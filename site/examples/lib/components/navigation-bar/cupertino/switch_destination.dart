import 'package:cupertino_ui/cupertino_ui.dart';

class SwitchDestination extends StatefulWidget {
  const SwitchDestination({super.key});
  @override
  State<SwitchDestination> createState() => _SwitchDestinationState();
}

class _SwitchDestinationState extends State<SwitchDestination> {
  int selected = 0;
  static const items = [
    BottomNavigationBarItem(icon: Icon(CupertinoIcons.house), label: 'Home'),
    BottomNavigationBarItem(icon: Icon(CupertinoIcons.search), label: 'Search'),
  ];

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 440),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(selected == 0 ? 'Home page' : 'Search page'),
        const SizedBox(height: 12),
        CupertinoTabBar(
          currentIndex: selected,
          onTap: (next) => setState(() => selected = next),
          items: items,
        ),
      ],
    ),
  );
}
