import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Icons;
import 'package:ledger_ui/ledger_ui.dart';

class SwitchDestination extends StatefulWidget {
  const SwitchDestination({super.key});
  @override
  State<SwitchDestination> createState() => _SwitchDestinationState();
}

class _SwitchDestinationState extends State<SwitchDestination> {
  int selected = 0;
  static const destinations = [
    LedgerNavItem(Icons.home_outlined, 'Home'),
    LedgerNavItem(Icons.search, 'Search'),
  ];

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(selected == 0 ? 'Home page' : 'Search page'),
      const SizedBox(height: 12),
      LedgerNavBar(
        items: destinations,
        selectedIndex: selected,
        onDestinationSelected: (next) => setState(() => selected = next),
      ),
    ],
  );
}
