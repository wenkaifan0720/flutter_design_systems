/// The shell without a router (lead call 9): [ExpressiveShellScaffold] under
/// an app that keeps its own branches — one plain `Navigator` per tab in an
/// `IndexedStack` — as the package's example runs. The bar on a phone and
/// the rail from 600dp, the selection, the bar yielding while a branch has
/// a page pushed, the band every root reserves, the media ground and the
/// collapsing action. The host app's go_router path is `shell_test.dart`'s, where
/// `ExpressiveShell` drives this same scaffold.
library;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

final ExpressiveThemeData _theme = ExpressiveThemeData.preset(
  'baseline',
  Brightness.light,
);

const ValueKey<String> _actionKey = ValueKey<String>('shell-action');
const ValueKey<String> _accessoryKey = ValueKey<String>('shell-accessory');
const ValueKey<String> _homeList = ValueKey<String>('list-home');
const double _accessoryHeight = 48;

const List<NavTab> _tabs = <NavTab>[
  NavTab(
    icon: ExpressiveSymbols.home,
    label: 'Home',
    location: '/home',
    key: ValueKey<String>('tab-home'),
  ),
  NavTab(
    icon: ExpressiveSymbols.explore,
    label: 'Explore',
    location: '/explore',
    key: ValueKey<String>('tab-explore'),
  ),
  NavTab(
    icon: ExpressiveSymbols.person,
    label: 'You',
    location: '/you',
    key: ValueKey<String>('tab-you'),
  ),
];

/// A root: its title over a long list that pads the band at its end.
class _Root extends StatelessWidget {
  const _Root(this.title, {this.listKey});

  final String title;
  final Key? listKey;

  @override
  Widget build(BuildContext context) => ListView(
    key: listKey,
    padding: EdgeInsets.only(bottom: ExpressiveShellInsets.of(context)),
    children: <Widget>[
      Text(title),
      for (var row = 0; row < 40; row++)
        SizedBox(height: 48, child: Text('$title row $row')),
    ],
  );
}

/// The app: the scaffold over one navigator per tab, the selected one on
/// show, a page pushed over a root yielding the bar.
class _App extends StatefulWidget {
  const _App({
    required this.tabs,
    required this.action,
    required this.accessory,
  });

  final List<NavTab> tabs;
  final ShellAction? action;
  final bool accessory;

  @override
  State<_App> createState() => _AppState();
}

class _AppState extends State<_App> {
  int tab = 0;
  late final List<List<String>> stacks = <List<String>>[
    for (final tab in widget.tabs) <String>[tab.location],
  ];
  late final List<GlobalKey<NavigatorState>> navigators =
      <GlobalKey<NavigatorState>>[
        for (final _ in widget.tabs) GlobalKey<NavigatorState>(),
      ];
  final List<int> selections = <int>[];

  void push(String location) =>
      setState(() => stacks[tab] = <String>[...stacks[tab], location]);

  void select(int index) => setState(() {
    selections.add(index);
    if (index == tab) stacks[index] = <String>[widget.tabs[index].location];
    tab = index;
  });

  Widget _page(String location) {
    if (location.endsWith('/detail')) {
      // Its own back: the tab's navigator, not the app's.
      return Builder(
        builder: (context) => Center(
          child: GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: const Text('Detail'),
          ),
        ),
      );
    }
    final at = widget.tabs.indexWhere((t) => t.location == location);
    return _Root(
      '${widget.tabs[at].label} root',
      listKey: at == 0 ? _homeList : null,
    );
  }

  @override
  Widget build(BuildContext context) => ExpressiveShellScaffold(
    tabs: widget.tabs,
    selectedIndex: tab,
    onDestinationSelected: select,
    barVisible: stacks[tab].length <= 1,
    action: widget.action,
    accessory: widget.accessory
        ? const ColoredBox(
            key: _accessoryKey,
            color: Color(0xFF808080),
            child: SizedBox(height: _accessoryHeight),
          )
        : null,
    body: IndexedStack(
      index: tab,
      sizing: StackFit.expand,
      children: <Widget>[
        for (var i = 0; i < widget.tabs.length; i++)
          Navigator(
            key: navigators[i],
            pages: <Page<void>>[
              for (final location in stacks[i])
                ExpressivePage<void>(
                  key: ValueKey<String>(location),
                  child: _page(location),
                ),
            ],
            onDidRemovePage: (page) => setState(
              () => stacks[i].remove((page.key! as ValueKey<String>).value),
            ),
          ),
      ],
    ),
  );
}

Future<_AppState> _pump(
  WidgetTester tester, {
  Size size = const Size(412, 892),
  // ui_core's host-side ShellAction constructor is not const (its
  // deprecated onTap), so the default is built here.
  bool withAction = true,
  ShellAction? customAction,
  bool accessory = true,
  List<NavTab> tabs = _tabs,
}) async {
  final action = !withAction
      ? null
      : customAction ??
            ShellAction(
              icon: ExpressiveSymbols.add,
              label: 'New',
              key: _actionKey,
              onPressed: _noop,
            );
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
  addTearDown(tester.view.reset);
  // The app's own navigator stands the shell; each tab's navigator is
  // nested under it, as an app on plain navigators runs.
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, navigator) => ExpressiveHost(
        light: _theme,
        brightness: Brightness.light,
        child: navigator!,
      ),
      home: _App(tabs: tabs, action: action, accessory: accessory),
    ),
  );
  await tester.pumpAndSettle();
  return tester.state<_AppState>(find.byType(_App));
}

void _noop(BuildContext context) {}

Offset _barSlide(WidgetTester tester) => tester
    .widget<FractionalTranslation>(
      find
          .ancestor(
            of: find.byType(ExpressiveNavigationBar, skipOffstage: false),
            matching: find.byType(FractionalTranslation, skipOffstage: false),
          )
          .first,
    )
    .translation;

Color _labelColor(WidgetTester tester, String label) =>
    tester.widget<Text>(find.text(label)).style!.color!;

void main() {
  testWidgets('a tab switches the body to its branch, every branch stays '
      'mounted, and the selection follows', (tester) async {
    final app = await _pump(tester);
    expect(find.byType(ExpressiveNavigationBar), findsOneWidget);
    expect(find.byType(ExpressiveNavigationRail), findsNothing);
    expect(_labelColor(tester, 'Home'), _theme.colors.secondary);

    await tester.tap(find.byKey(const ValueKey<String>('tab-explore')));
    await tester.pumpAndSettle();
    expect(app.selections, <int>[1]);
    expect(find.text('Explore root'), findsOneWidget);
    expect(find.text('Home root'), findsNothing);
    expect(find.text('Home root', skipOffstage: false), findsOneWidget);
    expect(_labelColor(tester, 'Explore'), _theme.colors.secondary);
    expect(_labelColor(tester, 'Home'), _theme.colors.onSurfaceVariant);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the accessory docks on the bar, the action stands 16dp above '
      'it at the end, and a root reserves the whole band', (tester) async {
    await _pump(tester);
    final bar = tester.getRect(find.byType(ExpressiveNavigationBar));
    final accessory = tester.getRect(find.byKey(_accessoryKey));
    final action = tester.getRect(find.byKey(_actionKey));
    expect(bar.height, 64 + 24, reason: '64dp over the 24dp inset');
    expect(bar.bottom, 892);
    expect(accessory.bottom, bar.top);
    expect(action.bottom, accessory.top - 16);
    expect(action.right, 412 - 16);
    // The band: the bar, the inset, the action and its gap, the accessory.
    const band = 64 + 24 + 56 + 16 + _accessoryHeight;
    expect(
      ExpressiveShellInsets.of(tester.element(find.text('Home root'))),
      band,
    );
    expect(892 - action.top, band);

    // The last row scrolls clear of the band. Twice: the first drag clamps at
    // the extent the list estimated before it built its last rows.
    for (var i = 0; i < 2; i++) {
      await tester.drag(find.byKey(_homeList), const Offset(0, -4000));
      await tester.pumpAndSettle();
    }
    final last = tester.getRect(find.text('Home root row 39'));
    expect(last.bottom, lessThanOrEqualTo(action.top));
  });

  testWidgets('the bar yields to a pushed page on a spring and stands '
      'again when it is popped', (tester) async {
    final app = await _pump(tester);
    expect(_barSlide(tester), Offset.zero);

    app.push('/home/detail');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 48));
    final leaving = _barSlide(tester).dy;
    expect(leaving, greaterThan(0), reason: 'the bar slides down');
    expect(leaving, lessThan(1), reason: 'on a spring, not at once');
    await tester.pumpAndSettle();
    expect(find.text('Detail'), findsOneWidget);
    expect(find.byType(ExpressiveNavigationBar), findsNothing);
    expect(find.byKey(_accessoryKey), findsNothing);
    expect(find.byKey(_actionKey), findsNothing);

    await tester.tap(find.text('Detail'));
    await tester.pumpAndSettle();
    expect(find.text('Home root'), findsOneWidget);
    expect(_barSlide(tester), Offset.zero);
    expect(find.byKey(_accessoryKey).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('from 600dp the rail stands at the leading edge with the '
      'action in its header, and the accessory docks under the content', (
    tester,
  ) async {
    await _pump(tester, size: const Size(840, 600));
    expect(find.byType(ExpressiveNavigationRail), findsOneWidget);
    expect(find.byType(ExpressiveNavigationBar), findsNothing);
    final rail = tester.getRect(find.byType(ExpressiveNavigationRail));
    expect(rail.left, 0);
    final action = tester.getRect(find.byKey(_actionKey));
    expect(rail.contains(action.center), isTrue);
    final accessory = tester.getRect(find.byKey(_accessoryKey));
    expect(accessory.left, rail.right);
    expect(accessory.bottom, 600 - 24, reason: 'over the bottom inset');
    expect(
      ExpressiveShellInsets.of(tester.element(find.text('Home root'))),
      _accessoryHeight + 24,
    );

    // The destination, not its label: the label lies under the item's
    // pressable, which takes the tap.
    await tester.tap(find.byKey(const ValueKey<String>('tab-you')));
    await tester.pumpAndSettle();
    expect(find.text('You root'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('from 1200dp the rail stands expanded, its labels beside the '
      'icons; below it the rail stays collapsed', (tester) async {
    for (final (width, expanded) in <(double, bool)>[
      (1199, false),
      (1200, true),
    ]) {
      await _pump(tester, size: Size(width, 800));
      final rail = tester.widget<ExpressiveNavigationRail>(
        find.byType(ExpressiveNavigationRail),
      );
      expect(rail.expanded, expanded, reason: '$width dp');
      final box = tester.getRect(find.byType(ExpressiveNavigationRail));
      expect(
        box.width,
        expanded
            ? greaterThanOrEqualTo(220)
            : ExpressiveChromeMetrics.railWidth,
        reason: '$width dp',
      );
      expect(box.contains(tester.getCenter(find.byKey(_actionKey))), isTrue);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('a media tab grounds the bar in the dark theme and ends the '
      'body at the bar\'s top', (tester) async {
    const media = <NavTab>[
      NavTab(
        icon: ExpressiveSymbols.home,
        label: 'Home',
        location: '/home',
        ground: ChromeGround.media,
      ),
      NavTab(
        icon: ExpressiveSymbols.person,
        label: 'You',
        location: '/you',
        key: ValueKey<String>('media-you'),
      ),
    ];
    await _pump(tester, tabs: media, withAction: false, accessory: false);
    expect(
      find.ancestor(
        of: find.byType(ExpressiveNavigationBar),
        matching: find.byType(ExpressiveMediaGround),
      ),
      findsOneWidget,
    );
    final bar = tester.getRect(find.byType(ExpressiveNavigationBar));
    final body = tester.getRect(find.byType(IndexedStack));
    expect(body.bottom, bar.top);

    await tester.tap(find.byKey(const ValueKey<String>('media-you')));
    await tester.pumpAndSettle();
    expect(
      find.ancestor(
        of: find.byType(ExpressiveNavigationBar),
        matching: find.byType(ExpressiveMediaGround),
      ),
      findsNothing,
    );
    expect(tester.getRect(find.byType(IndexedStack)).bottom, 892);
  });

  testWidgets('a collapsing action folds its label while the root scrolls '
      'down, and a change of tab brings it back', (tester) async {
    await _pump(
      tester,
      customAction: ExpressiveShellAction(
        icon: ExpressiveSymbols.chat,
        label: 'Ask',
        collapseOnScroll: true,
        onPressed: _noop,
      ),
    );
    expect(find.text('Ask'), findsOneWidget);
    await tester.drag(find.byKey(_homeList), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.text('Ask'), findsNothing);
    expect(find.bySemanticsLabel('Ask'), findsOneWidget);
    await tester.drag(find.byKey(_homeList), const Offset(0, 60));
    await tester.pumpAndSettle();
    expect(find.text('Ask'), findsOneWidget);
    await tester.drag(find.byKey(_homeList), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.text('Ask'), findsNothing);
    await tester.tap(find.byKey(const ValueKey<String>('tab-you')));
    await tester.pumpAndSettle();
    expect(find.text('Ask'), findsOneWidget);
  });
}
