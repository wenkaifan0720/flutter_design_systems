import 'package:flutter/widgets.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

class SwitchDestination extends StatefulWidget {
  const SwitchDestination({super.key});
  @override
  State<SwitchDestination> createState() => _SwitchDestinationState();
}

class _SwitchDestinationState extends State<SwitchDestination> {
  int selected = 0;
  static const destinations = [
    NeumorphicNavItem(
      label: 'Home',
      short: 'Home',
      icon: NeumorphicGlyphs.house,
    ),
    NeumorphicNavItem(
      label: 'Search',
      short: 'Search',
      icon: NeumorphicGlyphs.search,
    ),
  ];

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 740),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NeumorphicNavigationRail(
          items: destinations,
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
