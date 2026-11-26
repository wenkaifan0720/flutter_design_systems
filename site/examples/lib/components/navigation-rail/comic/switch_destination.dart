import 'package:flutter/widgets.dart';
import 'package:comic_ui/comic_ui.dart';

class SwitchDestination extends StatefulWidget {
  const SwitchDestination({super.key});
  @override
  State<SwitchDestination> createState() => _SwitchDestinationState();
}

class _SwitchDestinationState extends State<SwitchDestination> {
  int selected = 0;
  static const destinations = [
    ComicNavItem(label: 'Home', short: 'Home', icon: ComicGlyphs.house),
    ComicNavItem(label: 'Search', short: 'Search', icon: ComicGlyphs.search),
  ];

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 740),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ComicNavigationRail(
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
