import 'dart:ui' show Tristate;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_contract.dart';
import 'behaviour_harness.dart';

const List<DesignNavigationDestination> _destinations = [
  DesignNavigationDestination(label: 'Home', icon: IconData(0xe318)),
  DesignNavigationDestination(label: 'Mail', icon: IconData(0xe158)),
  DesignNavigationDestination(label: 'Settings', icon: IconData(0xe57f)),
];

final Map<int, DesignDestinationDetails> _seen = {};
DesignNavigationDetails? _navigation;

Widget _destination(
  BuildContext context,
  DesignNavigationDestination destination,
  DesignDestinationDetails details,
) {
  _seen[details.index] = details;
  return SizedBox(
    key: ValueKey('dest ${destination.label}'),
    height: 56,
    child: Center(child: Text(destination.label)),
  );
}

// The bare reference painter: a 64-high bar of equal destinations, an
// 80-wide rail, a 240-wide sidebar.
Widget _navigationOf(BuildContext context, DesignNavigationDetails details) {
  _navigation = details;
  return switch (details.mode) {
    DesignNavigationMode.bar => SizedBox(
      key: const ValueKey('nav'),
      height: 64,
      child: Row(
        children: [for (final d in details.destinations) Expanded(child: d)],
      ),
    ),
    DesignNavigationMode.rail => SizedBox(
      key: const ValueKey('nav'),
      width: 80,
      child: Column(children: details.destinations),
    ),
    DesignNavigationMode.sidebar => SizedBox(
      key: const ValueKey('nav'),
      width: 240,
      child: Column(children: details.destinations),
    ),
  };
}

// A body with something to focus.
Widget _body(String name) => Column(
  key: ValueKey('body $name'),
  children: [
    Text('$name page'),
    Focus(
      debugLabel: '$name field',
      child: Builder(
        builder: (context) => SizedBox(
          key: ValueKey('$name field'),
          width: 44,
          height: 44,
          child: Text(Focus.of(context).hasFocus ? 'focused' : ''),
        ),
      ),
    ),
  ],
);

// A shell whose selection the host keeps.
class _Host extends StatefulWidget {
  const _Host({
    this.mode,
    this.enabled = true,
    this.disabled = const {},
    this.branches = false,
    this.backBehavior = DesignBranchBackBehavior.firstDestination,
    this.navigatorKeys,
  });

  final DesignNavigationMode? mode;
  final bool enabled;
  final Set<int> disabled;
  final bool branches;
  final DesignBranchBackBehavior backBehavior;
  final List<GlobalKey<NavigatorState>>? navigatorKeys;

  @override
  State<_Host> createState() => _HostState();
}

final List<int> _chosen = [];
final List<String> _branchBuilds = [];

class _HostState extends State<_Host> {
  int selected = 0;
  bool show = true;

  void _choose(int i) {
    _chosen.add(i);
    setState(() => selected = i);
  }

  void showNavigation(bool value) => setState(() => show = value);

  @override
  Widget build(BuildContext context) {
    final destinations = [
      for (var i = 0; i < _destinations.length; i++)
        widget.disabled.contains(i)
            ? DesignNavigationDestination(
                label: _destinations[i].label,
                icon: _destinations[i].icon,
                enabled: false,
              )
            : _destinations[i],
    ];
    if (widget.branches) {
      return DesignAdaptiveShell.branches(
        destinations: destinations,
        selectedIndex: selected,
        onDestinationSelected: widget.enabled ? _choose : null,
        destinationBuilder: _destination,
        navigationBuilder: _navigationOf,
        mode: widget.mode,
        showNavigation: show,
        backBehavior: widget.backBehavior,
        navigatorKeys: widget.navigatorKeys,
        branches: [
          for (final d in _destinations)
            (context) {
              _branchBuilds.add(d.label);
              return _body(d.label);
            },
        ],
      );
    }
    return DesignAdaptiveShell(
      destinations: destinations,
      selectedIndex: selected,
      onDestinationSelected: widget.enabled ? _choose : null,
      destinationBuilder: _destination,
      navigationBuilder: _navigationOf,
      mode: widget.mode,
      showNavigation: show,
      body: _body(_destinations[selected].label),
    );
  }
}

_HostState _host(WidgetTester tester) => tester.state(find.byType(_Host));

bool _focusedOn(WidgetTester tester, String label) =>
    tester
        .getSemantics(find.byKey(ValueKey('dest $label')))
        .getSemanticsData()
        .flagsCollection
        .isFocused ==
    Tristate.isTrue;

bool _fieldFocused(String name) =>
    FocusManager.instance.primaryFocus?.debugLabel == '$name field';

Future<void> _width(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pump();
}

void main() {
  setUp(() {
    _seen.clear();
    _navigation = null;
    _chosen.clear();
    _branchBuilds.clear();
  });

  behaviourContract(
    'DesignAdaptiveShell',
    build: (c) => _Host(mode: DesignNavigationMode.bar, enabled: c.enabled),
    node: () => find.byKey(const ValueKey('dest Home')),
    semantics: isSemantics(
      label: 'Home\nTab 1 of 3',
      isSelected: true,
      isFocusable: true,
      hasTapAction: true,
    ),
    role: SemanticsRole.tab,
    disabled: isSemantics(
      label: 'Home\nTab 1 of 3',
      isSelected: true,
      hasEnabledState: true,
      isEnabled: false,
    ),
    root: () => find.byKey(const ValueKey('nav')),
    keyboard: (p) async {
      await p.tabInto();
      await p.key(LogicalKeyboardKey.arrowRight);
      expect(_focusedOn(p.tester, 'Mail'), isTrue);
      expect(_host(p.tester).selected, 0, reason: 'the arrows only move');
      await p.key(LogicalKeyboardKey.enter);
      expect(_host(p.tester).selected, 1, reason: 'Enter chooses');
      await p.key(LogicalKeyboardKey.end);
      expect(_focusedOn(p.tester, 'Settings'), isTrue);
      await p.key(LogicalKeyboardKey.arrowRight);
      expect(_focusedOn(p.tester, 'Home'), isTrue, reason: 'it wraps');
      await p.key(LogicalKeyboardKey.space);
      expect(_host(p.tester).selected, 0);
      await p.key(LogicalKeyboardKey.f6);
      expect(_fieldFocused('Home'), isTrue, reason: 'F6: the body');
      await p.key(LogicalKeyboardKey.f6);
      expect(_focusedOn(p.tester, 'Home'), isTrue, reason: 'and back round');
      await p.key(LogicalKeyboardKey.f6, shift: true);
      expect(_fieldFocused('Home'), isTrue, reason: 'Shift+F6 the other way');
    },
    rtl: (p) async {
      await p.tabInto();
      await p.key(LogicalKeyboardKey.arrowLeft);
      expect(_focusedOn(p.tester, 'Mail'), isTrue, reason: 'left is on');
      expect(
        p.tester.getRect(find.byKey(const ValueKey('dest Home'))).left,
        greaterThan(
          p.tester.getRect(find.byKey(const ValueKey('dest Mail'))).left,
        ),
      );
    },
    motion: (p) async {
      _host(p.tester).showNavigation(false);
      await p.tester.pump();
    },
  );

  test('window size classes and modes by width, Material\'s breakpoints', () {
    expect(
      [
        for (final w in [0.0, 599, 600, 839, 840, 1199, 1200, 1599, 1600])
          DesignWindowSizeClass.fromWidth(w.toDouble()),
      ],
      [
        DesignWindowSizeClass.compact,
        DesignWindowSizeClass.compact,
        DesignWindowSizeClass.medium,
        DesignWindowSizeClass.medium,
        DesignWindowSizeClass.expanded,
        DesignWindowSizeClass.expanded,
        DesignWindowSizeClass.large,
        DesignWindowSizeClass.large,
        DesignWindowSizeClass.extraLarge,
      ],
    );
    expect(
      [
        for (final w in [390.0, 768, 1000, 1440, 1920])
          DesignNavigationMode.fromWidth(w.toDouble()),
      ],
      [
        DesignNavigationMode.bar,
        DesignNavigationMode.rail,
        DesignNavigationMode.rail,
        DesignNavigationMode.sidebar,
        DesignNavigationMode.sidebar,
      ],
    );
  });

  testWidgets('a phone has a bar along the bottom, a tablet a rail at the '
      'start, a desktop a sidebar; the body keeps its state', (tester) async {
    late DesignWindowSizeClass size;
    await _width(tester, 390);
    await tester.pumpWidget(
      harness(
        Builder(
          builder: (context) {
            size = DesignWindowSizeClass.of(context);
            return const _Host();
          },
        ),
      ),
    );
    expect(size, DesignWindowSizeClass.compact);
    expect(_navigation!.mode, DesignNavigationMode.bar);
    final nav = tester.getRect(find.byKey(const ValueKey('nav')));
    expect(nav, const Rect.fromLTWH(0, 636, 390, 64));
    expect(
      tester.getRect(find.byKey(const ValueKey('body Home'))).bottom,
      lessThanOrEqualTo(636),
    );
    expect(_seen[0]!.mode, DesignNavigationMode.bar);
    expect(_seen[0]!.count, 3);
    expect(_seen[0]!.states, contains(WidgetState.selected));

    await tester.tap(find.text('Mail'));
    await tester.pumpAndSettle();
    State field() => tester.state(
      find
          .ancestor(
            of: find.byKey(const ValueKey('Mail field')),
            matching: find.byType(Focus),
          )
          .first,
    );
    final body = field();
    await _width(tester, 768);
    expect(size, DesignWindowSizeClass.medium);
    expect(_navigation!.mode, DesignNavigationMode.rail);
    expect(
      tester.getRect(find.byKey(const ValueKey('nav'))),
      const Rect.fromLTWH(0, 0, 80, 700),
    );
    expect(tester.getRect(find.byKey(const ValueKey('body Mail'))).left, 80);
    expect(field(), same(body), reason: 'the body moved with its state');
    await _width(tester, 1440);
    expect(_navigation!.mode, DesignNavigationMode.sidebar);
    expect(tester.getSize(find.byKey(const ValueKey('nav'))).width, 240);
  });

  testWidgets('right to left, the rail is at the right', (tester) async {
    await _width(tester, 768);
    await tester.pumpWidget(
      harness(const _Host(), textDirection: TextDirection.rtl),
    );
    expect(tester.getRect(find.byKey(const ValueKey('nav'))).right, 768);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(_focusedOn(tester, 'Mail'), isTrue, reason: 'a rail: Down');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(_focusedOn(tester, 'Home'), isTrue);
  });

  testWidgets('the body gives the navigation its side\'s safe inset', (
    tester,
  ) async {
    late EdgeInsets padding;
    Widget app(DesignNavigationMode mode) => harness(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(800, 600),
          padding: EdgeInsets.fromLTRB(20, 0, 0, 34),
        ),
        child: DesignAdaptiveShell(
          destinations: _destinations,
          selectedIndex: 0,
          onDestinationSelected: (_) {},
          destinationBuilder: _destination,
          navigationBuilder: _navigationOf,
          mode: mode,
          body: Builder(
            builder: (context) {
              padding = MediaQuery.paddingOf(context);
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );
    await tester.pumpWidget(app(DesignNavigationMode.bar));
    expect(padding, const EdgeInsets.only(left: 20));
    await tester.pumpWidget(app(DesignNavigationMode.rail));
    expect(padding, const EdgeInsets.only(bottom: 34));
  });

  testWidgets('the bar springs away while a page hides it, and back', (
    tester,
  ) async {
    await _width(tester, 390);
    await tester.pumpWidget(harness(const _Host()));
    final host = _host(tester);
    host.showNavigation(false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final mid = _navigation!.visibility.value;
    expect(mid, inExclusiveRange(0, 1));
    await tester.pumpAndSettle();
    expect(_navigation!.visibility.value, 0);
    expect(tester.getRect(find.byKey(const ValueKey('nav'))).top, 700);
    expect(
      tester.getRect(find.byKey(const ValueKey('body Home'))).height,
      700,
      reason: 'the body takes its room',
    );
    // Hidden, it takes no focus.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(_fieldFocused('Home'), isTrue);
    host.showNavigation(true);
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(const ValueKey('nav'))).top, 636);
  });

  testWidgets('a bar is a tab bar to a screen reader; a sidebar the '
      'navigation menu', (tester) async {
    final semantics = tester.ensureSemantics();
    await _width(tester, 390);
    await tester.pumpWidget(harness(const _Host()));
    var tab = tester.getSemantics(find.byKey(const ValueKey('dest Home')));
    expect(tab.parent!.role, SemanticsRole.tabBar);
    await _width(tester, 1440);
    tab = tester.getSemantics(find.byKey(const ValueKey('dest Home')));
    expect(tab.parent!.label, 'Navigation menu');
    expect(tab.getSemanticsData().label, 'Home\nTab 1 of 3');
    semantics.dispose();
  });

  testWidgets('a bar that holds an action beside its destinations: the '
      'group the look places round them is the tab bar, the action beside '
      'it; in a rail the group adds nothing', (tester) async {
    final semantics = tester.ensureSemantics();
    await _width(tester, 390);
    Widget shell(DesignNavigationMode mode) => harness(
      DesignAdaptiveShell(
        mode: mode,
        destinations: _destinations,
        selectedIndex: 0,
        onDestinationSelected: (_) {},
        destinationBuilder: _destination,
        navigationBuilder: (context, details) {
          final bar = details.mode == DesignNavigationMode.bar;
          final destinations = details.group(
            Flex(
              direction: bar ? Axis.horizontal : Axis.vertical,
              children: [
                for (final d in details.destinations)
                  bar ? Expanded(child: d) : d,
              ],
            ),
          );
          final compose = Semantics(
            key: const ValueKey('compose'),
            container: true,
            button: true,
            label: 'Compose',
            onTap: () {},
            child: const SizedBox.square(dimension: 48),
          );
          return bar
              ? SizedBox(
                  height: 64,
                  child: Row(
                    children: [
                      Expanded(child: destinations),
                      compose,
                    ],
                  ),
                )
              : SizedBox(
                  width: 80,
                  child: Column(children: [compose, destinations]),
                );
        },
        body: _body('Home'),
      ),
    );
    await tester.pumpWidget(shell(DesignNavigationMode.bar));
    expect(tester.takeException(), isNull);
    final tab = tester.getSemantics(find.byKey(const ValueKey('dest Home')));
    final tabBar = tab.parent!;
    expect(tabBar.role, SemanticsRole.tabBar);
    var tabs = 0;
    tabBar.visitChildren((child) {
      // A destination's node, its tab merged into it.
      expect(child.getSemanticsData().role, SemanticsRole.tab);
      tabs++;
      return true;
    });
    expect(tabs, 3);
    final compose = tester.getSemantics(find.byKey(const ValueKey('compose')));
    expect(compose.getSemanticsData().label, 'Compose');
    expect(compose.parent, same(tabBar.parent));
    expect(compose.parent!.role, isNot(SemanticsRole.tabBar));
    // A rail: the destinations and the action in the navigation, no tab
    // bar.
    await tester.pumpWidget(shell(DesignNavigationMode.rail));
    expect(tester.takeException(), isNull);
    final railTab = tester.getSemantics(
      find.byKey(const ValueKey('dest Home')),
    );
    expect(railTab.parent!.role, isNot(SemanticsRole.tabBar));
    expect(
      tester.getSemantics(find.byKey(const ValueKey('compose'))).parent,
      same(railTab.parent),
    );
    // Back to a bar, the group gone: the whole bar is the tab bar again.
    await tester.pumpWidget(harness(const _Host()));
    expect(
      tester.getSemantics(find.byKey(const ValueKey('dest Home'))).parent!.role,
      SemanticsRole.tabBar,
    );
    semantics.dispose();
  });

  testWidgets('a disabled destination is skipped; the stop moves off it', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(const _Host(mode: DesignNavigationMode.bar, disabled: {0, 1})),
    );
    // The body's field, then the destinations' one stop.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(_focusedOn(tester, 'Settings'), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(_focusedOn(tester, 'Settings'), isTrue, reason: 'nowhere else');
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    expect(_focusedOn(tester, 'Settings'), isTrue);
  });

  group('branches', () {
    Future<NavigatorState> navigator(WidgetTester tester, String name) async =>
        tester.state<NavigatorState>(
          find
              .ancestor(
                of: find.text('$name page'),
                matching: find.byType(Navigator),
              )
              .first,
        );

    Route<void> page(String name) => PageRouteBuilder<void>(
      pageBuilder: (context, _, _) => Text('$name detail'),
    );

    testWidgets('each keeps its own stack, built when first shown', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(const _Host(mode: DesignNavigationMode.bar, branches: true)),
      );
      expect(_branchBuilds.toSet(), {'Home'});
      unawaited((await navigator(tester, 'Home')).push(page('Home')));
      await tester.pumpAndSettle();
      expect(find.text('Home detail'), findsOneWidget);
      await tester.tap(find.text('Mail'));
      await tester.pumpAndSettle();
      expect(_branchBuilds.toSet(), {'Home', 'Mail'}, reason: 'not Settings');
      expect(find.text('Home detail'), findsNothing, reason: 'offstage');
      expect(find.text('Mail page'), findsOneWidget);
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(find.text('Home detail'), findsOneWidget, reason: 'kept');
      // The selected destination again: its root.
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(find.text('Home detail'), findsNothing);
      expect(find.text('Home page'), findsOneWidget);
      expect(_chosen, [1, 0, 0]);
    });

    testWidgets('back pops the branch, then goes to the first destination, '
        'then leaves', (tester) async {
      await tester.pumpWidget(
        harness(const _Host(mode: DesignNavigationMode.bar, branches: true)),
      );
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      unawaited((await navigator(tester, 'Settings')).push(page('Settings')));
      await tester.pumpAndSettle();
      expect(await tester.binding.handlePopRoute(), isTrue);
      await tester.pumpAndSettle();
      expect(find.text('Settings detail'), findsNothing);
      expect(find.text('Settings page'), findsOneWidget);
      expect(await tester.binding.handlePopRoute(), isTrue);
      await tester.pumpAndSettle();
      expect(_host(tester).selected, 0);
      expect(await tester.binding.handlePopRoute(), isFalse, reason: 'out');
    });

    testWidgets('history goes back through the destinations chosen', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(
          const _Host(
            mode: DesignNavigationMode.bar,
            branches: true,
            backBehavior: DesignBranchBackBehavior.history,
          ),
        ),
      );
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mail'));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(_host(tester).selected, 2);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(_host(tester).selected, 0);
      expect(await tester.binding.handlePopRoute(), isFalse);
    });

    testWidgets('none leaves from a branch\'s root; given keys push from '
        'outside', (tester) async {
      final keys = [for (var i = 0; i < 3; i++) GlobalKey<NavigatorState>()];
      await tester.pumpWidget(
        harness(
          _Host(
            mode: DesignNavigationMode.bar,
            branches: true,
            backBehavior: DesignBranchBackBehavior.none,
            navigatorKeys: keys,
          ),
        ),
      );
      await tester.tap(find.text('Mail'));
      await tester.pumpAndSettle();
      expect(await tester.binding.handlePopRoute(), isFalse);
      unawaited(keys[1].currentState!.push(page('Mail')));
      await tester.pumpAndSettle();
      expect(find.text('Mail detail'), findsOneWidget);
    });

    testWidgets('a hidden branch takes no focus and says nothing', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        harness(const _Host(mode: DesignNavigationMode.bar, branches: true)),
      );
      await tester.tap(find.text('Mail'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Home page'), findsNothing);
      for (var i = 0; i < 6; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(_fieldFocused('Home'), isFalse);
      }
      semantics.dispose();
    });
  });

  testWidgets('a shown toaster is one more pane: F6 reaches the newest toast '
      'after the body, and Escape there goes back', (tester) async {
    await _width(tester, 768);
    final toaster = GlobalKey<RawToasterState>();
    await tester.pumpWidget(
      harness(
        RawToaster(
          key: toaster,
          toastBuilder: (context, details) =>
              SizedBox(height: 48, child: Text(details.toast.message)),
          child: const _Host(),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(_focusedOn(tester, 'Home'), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.f6);
    await tester.pumpAndSettle();
    expect(_fieldFocused('Home'), isTrue, reason: 'no toast: the body');
    await tester.sendKeyEvent(LogicalKeyboardKey.f6);
    await tester.pumpAndSettle();
    expect(_focusedOn(tester, 'Home'), isTrue, reason: 'and round');

    toaster.currentState!.show(
      const RawToast(message: 'Saved', duration: null),
    );
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.f6);
    await tester.sendKeyEvent(LogicalKeyboardKey.f6);
    await tester.pumpAndSettle();
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'RawToast',
      reason: 'the toast after the body',
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Saved'), findsNothing);
    expect(_fieldFocused('Home'), isTrue, reason: 'back where it was');
    await tester.sendKeyEvent(LogicalKeyboardKey.f6);
    await tester.pumpAndSettle();
    expect(_focusedOn(tester, 'Home'), isTrue);
  });

  testWidgets('from outside every pane, F6 goes to the first', (tester) async {
    await _width(tester, 768);
    await tester.pumpWidget(
      harness(
        RawToaster(
          toastBuilder: (context, details) => Text(details.toast.message),
          child: const Column(
            children: [
              Focus(
                debugLabel: 'toolbar',
                autofocus: true,
                child: SizedBox(height: 44),
              ),
              Expanded(child: _Host()),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'toolbar');
    await tester.sendKeyEvent(LogicalKeyboardKey.f6);
    await tester.pumpAndSettle();
    expect(_focusedOn(tester, 'Home'), isTrue, reason: 'the rail, first');
  });

  test('it describes itself', () {
    final text = DesignAdaptiveShell.branches(
      destinations: _destinations,
      selectedIndex: 1,
      onDestinationSelected: null,
      destinationBuilder: _destination,
      navigationBuilder: _navigationOf,
      branches: [for (final _ in _destinations) (context) => const SizedBox()],
      backBehavior: DesignBranchBackBehavior.history,
      mode: DesignNavigationMode.rail,
      showNavigation: false,
      dampingRatio: .5,
    ).toDiagnosticsNode().toStringDeep();
    for (final s in [
      'destinations: [Home, Mail, Settings]',
      'selectedIndex: 1',
      'branches: 3',
      'backBehavior: history',
      'mode: rail',
      'navigation hidden',
      'dampingRatio: 0.5',
    ]) {
      expect(text, contains(s));
    }
  });

  // The width × direction × text scale matrix.
  for (final width in [390.0, 768.0, 1440.0]) {
    for (final direction in TextDirection.values) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('${width.round()} wide, $direction, text ×$scale: the '
            'navigation on its side, F6 between it and the body', (
          tester,
        ) async {
          await _width(tester, width);
          await tester.pumpWidget(
            harness(
              const _Host(branches: true),
              textDirection: direction,
              textScale: scale,
            ),
          );
          expect(tester.takeException(), isNull);
          final nav = tester.getRect(find.byKey(const ValueKey('nav')));
          if (width < 600) {
            expect(nav.bottom, 700);
          } else if (direction == TextDirection.ltr) {
            expect(nav.left, 0);
          } else {
            expect(nav.right, width);
          }
          await tester.sendKeyEvent(LogicalKeyboardKey.f6);
          await tester.pumpAndSettle();
          final first = FocusManager.instance.primaryFocus;
          await tester.sendKeyEvent(LogicalKeyboardKey.f6);
          await tester.pumpAndSettle();
          expect(FocusManager.instance.primaryFocus, isNot(first));
          await tester.sendKeyEvent(LogicalKeyboardKey.f6);
          await tester.pumpAndSettle();
          expect(FocusManager.instance.primaryFocus, first, reason: 'round');
        }, tags: 'sweep');
      }
    }
  }
}

void unawaited(Future<void> future) {}
