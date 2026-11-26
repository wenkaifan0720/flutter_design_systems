import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Icons;
import 'package:gloss_ui/gloss_ui.dart';

class SwitchDestination extends StatefulWidget {
  const SwitchDestination({super.key});
  @override
  State<SwitchDestination> createState() => _SwitchDestinationState();
}

class _SwitchDestinationState extends State<SwitchDestination> {
  int selected = 0;
  static const destinations = [
    GlossDestination(icon: Icons.home_outlined, label: 'Home'),
    GlossDestination(icon: Icons.search, label: 'Search'),
  ];

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(selected == 0 ? 'Home page' : 'Search page'),
      const SizedBox(height: 12),
      GlossNavigationBar(
        destinations: destinations,
        selectedIndex: selected,
        onDestinationSelected: (next) => setState(() => selected = next),
      ),
    ],
  );
}
