/// The shell group's demo: a small live app on a plain `Navigator` — four
/// tabs that keep their own stacks behind [ExpressiveShellScaffold]'s
/// flexible navigation bar (the rail from 600dp), a now-playing accessory
/// docked on the bar, a floating action that raises a sheet on the root
/// navigator (the bar stays put under it), and a row that pushes a page off
/// a root (the bar slides away and comes back on the way home). An app
/// under go_router stands the same scaffold as `ExpressiveShell`.
library;

import 'package:flutter/material.dart' show MaterialPage;
import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

import '../kit.dart';
import '../kit_stack.dart';

/// The shell group's demo, in [brightness].
Widget kitShellDemo(Brightness brightness) =>
    KitStack(brightness: brightness, page: _page);

const List<NavTab> _tabs = <NavTab>[
  NavTab(icon: ExpressiveSymbols.today, label: 'Today', location: '/today'),
  NavTab(
    icon: ExpressiveSymbols.explore,
    label: 'Explore',
    location: '/explore',
  ),
  NavTab(
    icon: ExpressiveSymbols.headphones,
    label: 'Library',
    location: '/library',
  ),
  NavTab(icon: ExpressiveSymbols.person, label: 'You', location: '/you'),
];

/// The root navigator's pages: the shell, and the sheet raised over it.
Page<void> _page(String location, LocalKey key) => switch (location) {
  '/new' => ExpressiveSheetPage<void>(
    key: key,
    child: const KitPage(
      title: 'New playlist',
      children: <Widget>[Text('Raised on the root navigator, over the bar.')],
    ),
  ),
  _ => MaterialPage<void>(key: key, child: const _Shell()),
};

/// The shell: one navigator per tab, each keeping its own stack, the
/// selected one on show.
class _Shell extends StatefulWidget {
  const _Shell();

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  int _tab = 0;

  /// Each tab's locations, its root first.
  final List<List<String>> _stacks = <List<String>>[
    for (final tab in _tabs) <String>[tab.location],
  ];

  /// Each tab's navigator: the system back pops the selected one's page.
  final List<GlobalKey<NavigatorState>> _navigators =
      <GlobalKey<NavigatorState>>[
        for (final _ in _tabs) GlobalKey<NavigatorState>(),
      ];

  /// Pushes [location] onto the selected tab's stack.
  static void push(BuildContext context, String location) {
    final shell = context.findAncestorStateOfType<_ShellState>()!;
    shell.setState(
      () => shell._stacks[shell._tab] = <String>[
        ...shell._stacks[shell._tab],
        location,
      ],
    );
  }

  /// Selects tab [index]; selecting the tab on show returns it to its root.
  void _select(int index) => setState(() {
    if (index == _tab) _stacks[index] = <String>[_tabs[index].location];
    _tab = index;
  });

  void _removed(int tab, Page<Object?> page) {
    final key = page.key;
    if (key is! ValueKey<String>) return;
    setState(
      () => _stacks[tab] = <String>[
        for (final location in _stacks[tab])
          if (location != key.value) location,
      ],
    );
  }

  @override
  Widget build(BuildContext context) => ExpressiveShellScaffold(
    tabs: _tabs,
    selectedIndex: _tab,
    onDestinationSelected: _select,
    barVisible: _stacks[_tab].length <= 1,
    action: ShellAction(
      icon: ExpressiveSymbols.add,
      label: 'New playlist',
      onPressed: (context) => KitStack.push(context, '/new'),
    ),
    accessory: const _NowPlaying(),
    // A page pushed in the selected tab takes the system back first.
    body: PopScope<void>(
      canPop: _stacks[_tab].length <= 1,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _navigators[_tab].currentState?.maybePop();
      },
      child: IndexedStack(
        index: _tab,
        sizing: StackFit.expand,
        children: <Widget>[
          for (var i = 0; i < _tabs.length; i++)
            Navigator(
              key: _navigators[i],
              pages: <Page<void>>[
                for (final location in _stacks[i])
                  ExpressivePage<void>(
                    key: ValueKey<String>(location),
                    child: _branchPage(location),
                  ),
              ],
              onDidRemovePage: (page) => _removed(i, page),
            ),
        ],
      ),
    ),
  );
}

/// What a tab's location shows.
Widget _branchPage(String location) => switch (location) {
  '/today' => Builder(
    builder: (context) => KitPage(
      title: 'Today',
      children: <Widget>[
        const Text(
          'Four tabs, each keeping its own stack. The bar '
          'stands on every root; from 600dp the shell stands '
          'the rail instead.',
        ),
        KitAction(
          'Open “Morning focus”',
          onTap: () => _ShellState.push(context, '/today/mix'),
        ),
        KitAction(
          'New playlist (the sheet rises over the bar)',
          onTap: () => KitStack.push(context, '/new'),
        ),
      ],
    ),
  ),
  '/today/mix' => Builder(
    builder: (context) => KitPage(
      title: 'Morning focus',
      children: <Widget>[
        const Text(
          'Pushed off a root: the bar, the accessory and '
          'the action have slid away.',
        ),
        KitAction('Back', onTap: () => Navigator.of(context).pop()),
      ],
    ),
  ),
  _ => KitPage(
    title: _tabs.firstWhere((tab) => tab.location == location).label,
    children: const <Widget>[Text('A branch root keeps its own stack.')],
  ),
};

/// The accessory: a now-playing strip docked on the bar.
class _NowPlaying extends StatelessWidget {
  const _NowPlaying();

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    return ColoredBox(
      color: t.colors.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ExpressiveSpacing.s16,
          vertical: ExpressiveSpacing.s12,
        ),
        child: Row(
          children: <Widget>[
            Icon(ExpressiveSymbols.musicNote, color: t.colors.primary),
            const SizedBox(width: ExpressiveSpacing.s12),
            Expanded(
              child: Text(
                'Slow tide · Harbour Lights',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.type.bodyMedium.copyWith(color: t.colors.onSurface),
              ),
            ),
            Icon(ExpressiveSymbols.pause, color: t.colors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
