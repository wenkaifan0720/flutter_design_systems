import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Icons;
import 'package:civic_ui/civic_ui.dart';

class SwitchDestination extends StatefulWidget {
  const SwitchDestination({super.key});
  @override
  State<SwitchDestination> createState() => _SwitchDestinationState();
}

class _SwitchDestinationState extends State<SwitchDestination> {
  int selected = 0;
  static const destinations = [
    CivicNavigationDestination(icon: Icons.home_outlined, label: 'Home'),
    CivicNavigationDestination(icon: Icons.search, label: 'Search'),
  ];

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 680),
    child: Column(
      children: [
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: CivicSideNavigation(
              destinations: destinations,
              selectedIndex: selected,
              onDestinationSelected: (next) => setState(() => selected = next),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(selected == 0 ? 'Home page' : 'Search page'),
      ],
    ),
  );
}
