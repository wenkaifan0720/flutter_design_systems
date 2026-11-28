import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Icons;
import 'package:ledger_ui/ledger_ui.dart';

class NavigateWorkspace extends StatefulWidget {
  const NavigateWorkspace({super.key});
  @override
  State<NavigateWorkspace> createState() => _NavigateWorkspaceState();
}

class _NavigateWorkspaceState extends State<NavigateWorkspace> {
  int selected = 0;

  @override
  Widget build(BuildContext context) => LedgerAppShell.branches(
    brand: 'Workspace',
    destinations: const [
      LedgerNavItem(Icons.home_outlined, 'Home'),
      LedgerNavItem(Icons.search, 'Search'),
    ],
    selectedIndex: selected,
    onDestinationSelected: (next) => setState(() => selected = next),
    branches: [
      (context) => const LedgerScreen(
        topBar: LedgerTopBar(title: 'Home'),
        body: Center(child: Text('Home page')),
      ),
      (context) => const LedgerScreen(
        topBar: LedgerTopBar(title: 'Search'),
        body: Center(child: Text('Search page')),
      ),
    ],
  );
}
