import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Icons;
import 'package:studio_ui/studio_ui.dart';

class SwitchDestination extends StatefulWidget {
  const SwitchDestination({super.key});
  @override
  State<SwitchDestination> createState() => _SwitchDestinationState();
}

class _SwitchDestinationState extends State<SwitchDestination> {
  int selected = 0;
  static const destinations = [
    StudioDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
    StudioDestination(icon: Icon(Icons.search), label: 'Search'),
  ];

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(selected == 0 ? 'Home page' : 'Search page'),
      const SizedBox(height: 12),
      StudioNavigationBar(
        destinations: destinations,
        selectedIndex: selected,
        onDestinationSelected: (next) => setState(() => selected = next),
      ),
    ],
  );
}
