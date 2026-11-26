import 'package:flutter/widgets.dart';
import 'package:terminal_ui/terminal_ui.dart';

class SwitchDestination extends StatefulWidget {
  const SwitchDestination({super.key});
  @override
  State<SwitchDestination> createState() => _SwitchDestinationState();
}

class _SwitchDestinationState extends State<SwitchDestination> {
  int selected = 0;
  static const destinations = [
    TermNavigationDestination(label: 'Home', glyph: '#'),
    TermNavigationDestination(label: 'Search', glyph: '?'),
  ];

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 680),
    child: Column(
      children: [
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: TermSideBar(
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
