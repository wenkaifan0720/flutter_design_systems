import 'package:material_ui/material_ui.dart';

class SwitchDestination extends StatefulWidget {
  const SwitchDestination({super.key});
  @override
  State<SwitchDestination> createState() => _SwitchDestinationState();
}

class _SwitchDestinationState extends State<SwitchDestination> {
  int selected = 0;
  static const destinations = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Home',
    ),
    NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
  ];

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 440),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(selected == 0 ? 'Home page' : 'Search page'),
        const SizedBox(height: 12),
        NavigationBar(
          selectedIndex: selected,
          onDestinationSelected: (next) => setState(() => selected = next),
          destinations: destinations,
        ),
      ],
    ),
  );
}
