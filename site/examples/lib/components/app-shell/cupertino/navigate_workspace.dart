import 'package:cupertino_ui/cupertino_ui.dart';

class NavigateWorkspace extends StatelessWidget {
  const NavigateWorkspace({super.key});

  @override
  Widget build(BuildContext context) => CupertinoTabScaffold(
    tabBar: CupertinoTabBar(items: _items),
    tabBuilder: (context, index) => CupertinoPageScaffold(
      child: Center(child: Text(index == 0 ? 'Home page' : 'Search page')),
    ),
  );
}

const _items = [
  BottomNavigationBarItem(icon: Icon(CupertinoIcons.house), label: 'Home'),
  BottomNavigationBarItem(icon: Icon(CupertinoIcons.search), label: 'Search'),
];
