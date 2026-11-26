import 'package:material_ui/material_ui.dart';

class NavigateWorkspace extends StatefulWidget {
  const NavigateWorkspace({super.key});
  @override
  State<NavigateWorkspace> createState() => _NavigateWorkspaceState();
}

class _NavigateWorkspaceState extends State<NavigateWorkspace> {
  int selected = 0;
  static const destinations = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Home',
    ),
    NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
  ];
  static const railDestinations = [
    NavigationRailDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: Text('Home'),
    ),
    NavigationRailDestination(icon: Icon(Icons.search), label: Text('Search')),
  ];

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final page = Center(
        child: Text(selected == 0 ? 'Home page' : 'Search page'),
      );
      void select(int next) => setState(() => selected = next);
      // A phone gets a bar along the bottom, a wider window a rail.
      if (constraints.maxWidth < 600) {
        return Scaffold(
          body: page,
          bottomNavigationBar: NavigationBar(
            selectedIndex: selected,
            onDestinationSelected: select,
            destinations: destinations,
          ),
        );
      }
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selected,
              onDestinationSelected: select,
              labelType: NavigationRailLabelType.all,
              destinations: railDestinations,
            ),
            const VerticalDivider(width: 1),
            Expanded(child: page),
          ],
        ),
      );
    },
  );
}
