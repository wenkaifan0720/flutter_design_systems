import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Icons;
import 'package:appliance_ui/appliance_ui.dart';

class SwitchDestination extends StatefulWidget {
  const SwitchDestination({super.key});
  @override
  State<SwitchDestination> createState() => _SwitchDestinationState();
}

class _SwitchDestinationState extends State<SwitchDestination> {
  int selected = 0;
  static const destinations = [
    ApplianceDestination(icon: Icons.home_outlined, label: 'Home'),
    ApplianceDestination(icon: Icons.search, label: 'Search'),
  ];

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(selected == 0 ? 'Home page' : 'Search page'),
      const SizedBox(height: 12),
      ApplianceNavigationBar(
        destinations: destinations,
        selectedIndex: selected,
        onSelected: (next) => setState(() => selected = next),
      ),
    ],
  );
}
