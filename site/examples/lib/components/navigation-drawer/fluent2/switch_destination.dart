import 'package:flutter/widgets.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

class SwitchDestination extends StatefulWidget {
  const SwitchDestination({super.key});
  @override
  State<SwitchDestination> createState() => _SwitchDestinationState();
}

class _SwitchDestinationState extends State<SwitchDestination> {
  int selected = 0;
  static const destinations = [
    Fluent2NavItem(Fluent2Icons.home, 'Home'),
    Fluent2NavItem(Fluent2Icons.search, 'Search'),
  ];

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 680),
    child: Column(
      children: [
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Fluent2NavigationDrawer(
              items: destinations,
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
