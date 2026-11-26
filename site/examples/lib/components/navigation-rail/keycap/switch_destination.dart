import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Icons;
import 'package:keycap_ui/keycap_ui.dart';

class SwitchDestination extends StatefulWidget {
  const SwitchDestination({super.key});
  @override
  State<SwitchDestination> createState() => _SwitchDestinationState();
}

class _SwitchDestinationState extends State<SwitchDestination> {
  int selected = 0;
  static const destinations = [
    KeycapDestination(icon: Icons.home_outlined, label: 'Home'),
    KeycapDestination(icon: Icons.search, label: 'Search'),
  ];

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 740),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KeycapNavigationRail(
          destinations: destinations,
          selectedIndex: selected,
          onDestinationSelected: (next) => setState(() => selected = next),
        ),
        Expanded(
          child: Center(
            child: Text(selected == 0 ? 'Home page' : 'Search page'),
          ),
        ),
      ],
    ),
  );
}
