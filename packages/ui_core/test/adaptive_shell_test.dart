import 'dart:ui' show Tristate;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';
import 'package:ui_core/src/internal/panes.dart';

import 'behaviour_contract.dart';
import 'behaviour_harness.dart';

const List<RawNavigationDestination> _destinations = [
  RawNavigationDestination(label: 'Home', icon: IconData(0xe318)),
  RawNavigationDestination(label: 'Mail', icon: IconData(0xe158)),
  RawNavigationDestination(label: 'Settings', icon: IconData(0xe57f)),
];

final Map<int, RawDestinationDetails> _seen = {};
RawNavigationDetails? _navigation;

Widget _destination(
  BuildContext context,
  RawNavigationDestination destination,
  RawDestinationDetails details,
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
Widget _navigationOf(BuildContext context, RawNavigationDetails details) {
  _navigation = details;
  return switch (details.mode) {
    RawNavigationMode.bar => SizedBox(
      key: const ValueKey('nav'),
      height: 64,
      child: Row(
        children: [for (final d in details.destinations) Expanded(child: d)],
      ),
    ),
    RawNavigationMode.rail => SizedBox(
      key: const ValueKey('nav'),
      width: 80,
      child: Column(children: details.destinations),
    ),
    RawNavigationMode.sidebar => SizedBox(
      key: const ValueKey('nav'),
      width: 240,
      child: Column(children: details.destinations),
    ),
    RawNavigationMode.top => SizedBox(
      key: const ValueKey('nav'),
      height: 56,
      child: Row(
        children: [for (final d in details.destinations) Expanded(child: d)],
      ),
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
    this.backBehavior = RawBranchBackBehavior.firstDestination,
    this.navigatorKeys,
    this.hideBarOnPush = true,
  });

  final RawNavigationMode? mode;
  final bool enabled;
  final Set<int> disabled;
  final bool branches;
  final RawBranchBackBehavior backBehavior;
  final List<GlobalKey<NavigatorState>>? navigatorKeys;
  final bool hideBarOnPush;

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
            ? RawNavigationDestination(
                label: _destinations[i].label,
                icon: _destinations[i].icon,
                enabled: false,
              )
            : _destinations[i],
    ];
    if (widget.branches) {
      return RawAdaptiveShell.branches(
        destinations: destinations,
        selectedIndex: selected,
        onDestinationSelected: widget.enabled ? _choose : null,
        destinationBuilder: _destination,
        navigationBuilder: _navigationOf,
        mode: widget.mode,
        showNavigation: show,
        backBehavior: widget.backBehavior,
        navigatorKeys: widget.navigatorKeys,
        hideBarOnPush: widget.hideBarOnPush,
        branches: [
          for (final d in _destinations)
            (context) {
              _branchBuilds.add(d.label);
              return _body(d.label);
            },
        ],
      );
    }
    return RawAdaptiveShell(
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
    'RawAdaptiveShell',
    build: (c) => _Host(mode: RawNavigationMode.bar, enabled: c.enabled),
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
          RawWindowSizeClass.fromWidth(w.toDouble()),
      ],
      [
        RawWindowSizeClass.compact,
        RawWindowSizeClass.compact,
        RawWindowSizeClass.medium,
        RawWindowSizeClass.medium,
        RawWindowSizeClass.expanded,
        RawWindowSizeClass.expanded,
        RawWindowSizeClass.large,
        RawWindowSizeClass.large,
        RawWindowSizeClass.extraLarge,
      ],
    );
    expect(
      [
        for (final w in [390.0, 768, 1000, 1440, 1920])
          RawNavigationMode.fromWidth(w.toDouble()),
      ],
      [
        RawNavigationMode.bar,
        RawNavigationMode.rail,
        RawNavigationMode.rail,
        RawNavigationMode.sidebar,
        RawNavigationMode.sidebar,
      ],
    );
  });

  testWidgets('a phone has a bar along the bottom, a tablet a rail at the '
      'start, a desktop a sidebar; the body keeps its state', (tester) async {
    late RawWindowSizeClass size;
    await _width(tester, 390);
    await tester.pumpWidget(
      harness(
        Builder(
          builder: (context) {
            size = RawWindowSizeClass.of(context);
            return const _Host();
          },
        ),
      ),
    );
    expect(size, RawWindowSizeClass.compact);
    expect(_navigation!.mode, RawNavigationMode.bar);
    final nav = tester.getRect(find.byKey(const ValueKey('nav')));
    expect(nav, const Rect.fromLTWH(0, 636, 390, 64));
    expect(
      tester.getRect(find.byKey(const ValueKey('body Home'))).bottom,
      lessThanOrEqualTo(636),
    );
    expect(_seen[0]!.mode, RawNavigationMode.bar);
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
    expect(size, RawWindowSizeClass.medium);
    expect(_navigation!.mode, RawNavigationMode.rail);
    expect(
      tester.getRect(find.byKey(const ValueKey('nav'))),
      const Rect.fromLTWH(0, 0, 80, 700),
    );
    expect(tester.getRect(find.byKey(const ValueKey('body Mail'))).left, 80);
    expect(field(), same(body), reason: 'the body moved with its state');
    await _width(tester, 1440);
    expect(_navigation!.mode, RawNavigationMode.sidebar);
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
    Widget app(RawNavigationMode mode) => harness(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(800, 600),
          padding: EdgeInsets.fromLTRB(20, 0, 0, 34),
        ),
        child: RawAdaptiveShell(
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
    await tester.pumpWidget(app(RawNavigationMode.bar));
    expect(padding, const EdgeInsets.only(left: 20));
    await tester.pumpWidget(app(RawNavigationMode.rail));
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
    Widget shell(RawNavigationMode mode) => harness(
      RawAdaptiveShell(
        mode: mode,
        destinations: _destinations,
        selectedIndex: 0,
        onDestinationSelected: (_) {},
        destinationBuilder: _destination,
        navigationBuilder: (context, details) {
          final bar = details.mode == RawNavigationMode.bar;
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
    await tester.pumpWidget(shell(RawNavigationMode.bar));
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
    await tester.pumpWidget(shell(RawNavigationMode.rail));
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
      harness(const _Host(mode: RawNavigationMode.bar, disabled: {0, 1})),
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
      // The bar stays under a pushed page, to choose another branch there.
      await tester.pumpWidget(
        harness(
          const _Host(
            mode: RawNavigationMode.bar,
            branches: true,
            hideBarOnPush: false,
          ),
        ),
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
        harness(const _Host(mode: RawNavigationMode.bar, branches: true)),
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
            mode: RawNavigationMode.bar,
            branches: true,
            backBehavior: RawBranchBackBehavior.history,
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
            mode: RawNavigationMode.bar,
            branches: true,
            backBehavior: RawBranchBackBehavior.none,
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
        harness(const _Host(mode: RawNavigationMode.bar, branches: true)),
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

  testWidgets('a toast keeps clear of the bar, as a snackbar of the bottom '
      'navigation bar, and follows it as it springs away', (tester) async {
    await _width(tester, 390);
    final toaster = GlobalKey<RawToasterState>();
    await tester.pumpWidget(
      harness(
        RawToaster(
          key: toaster,
          toastBuilder: (context, details) => SizedBox(
            key: const ValueKey('toast'),
            height: 48,
            child: Text(details.toast.message),
          ),
          child: const _Host(),
        ),
      ),
    );
    toaster.currentState!.show(
      const RawToast(message: 'Saved', duration: null),
    );
    await tester.pumpAndSettle();
    Rect toast() => tester.getRect(find.byKey(const ValueKey('toast')));
    final bar = tester.getRect(find.byKey(const ValueKey('nav')));
    expect(toast().bottom, moreOrLessEquals(bar.top - 16));
    // Half way through the bar's spring the toast is on its way down.
    _host(tester).showNavigation(false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    final moving = tester.getRect(find.byKey(const ValueKey('nav'))).top;
    await tester.pump();
    expect(toast().bottom, lessThanOrEqualTo(moving - 16 + 0.5));
    expect(toast().bottom, greaterThan(bar.top - 16));
    await tester.pumpAndSettle();
    expect(toast().bottom, moreOrLessEquals(700 - 16), reason: 'bar gone');
    // A rail, at the start edge, from top to bottom: no bar to keep clear of.
    _host(tester).showNavigation(true);
    await _width(tester, 768);
    await tester.pumpAndSettle();
    expect(toast().bottom, moreOrLessEquals(700 - 16), reason: 'a rail');
  });

  testWidgets('a heading and the text under it stay two nodes: in the body '
      'beside a bar and beside a rail, and under PaneCycle alone', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    for (final width in [390.0, 1200.0]) {
      await _width(tester, width);
      await tester.pumpWidget(
        harness(
          RawAdaptiveShell(
            destinations: _destinations,
            selectedIndex: 0,
            onDestinationSelected: (_) {},
            destinationBuilder: _destination,
            navigationBuilder: _navigationOf,
            body: headingAndText(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expectHeadingAndTextApart(tester);
    }
    await tester.pumpWidget(harness(PaneCycle(child: headingAndText())));
    expectHeadingAndTextApart(tester);
    semantics.dispose();
  });

  testWidgets('a route pushed over the shell lets the toasts go from its '
      'bar; back, they keep clear of the bar again', (tester) async {
    await _width(tester, 390);
    final toaster = GlobalKey<RawToasterState>();
    await tester.pumpWidget(
      harness(
        const _Host(),
        wrap: (context, navigator) => RawToaster(
          key: toaster,
          toastBuilder: (context, details) => SizedBox(
            key: const ValueKey('toast'),
            height: 48,
            child: Text(details.toast.message),
          ),
          child: navigator!,
        ),
      ),
    );
    toaster.currentState!.show(
      const RawToast(message: 'Saved', duration: null),
    );
    await tester.pumpAndSettle();
    Rect toast() => tester.getRect(find.byKey(const ValueKey('toast')));
    final bar = tester.getRect(find.byKey(const ValueKey('nav')));
    expect(toast().bottom, moreOrLessEquals(bar.top - 16));
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    unawaited(
      navigator.push(
        PageRouteBuilder<void>(
          pageBuilder: (context, _, _) => const SizedBox.expand(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(toast().bottom, moreOrLessEquals(700 - 16), reason: 'covered');
    navigator.pop();
    await tester.pumpAndSettle();
    expect(toast().bottom, moreOrLessEquals(bar.top - 16), reason: 'back');
  });

  testWidgets('a rail or a sidebar keeps the toasts beside it and never above '
      'or below it, edge to edge, under a top bar or over a status line; a bar '
      'under a top bar keeps them above it, as Scaffold keeps a snackbar above '
      'its bottomNavigationBar alone', (tester) async {
    final toaster = GlobalKey<RawToasterState>();
    Widget app({
      bool topBar = false,
      bool statusLine = false,
      AlignmentGeometry alignment = AlignmentDirectional.bottomCenter,
    }) => harness(
      RawToaster(
        key: toaster,
        alignment: alignment,
        toastBuilder: (context, details) => SizedBox(
          key: const ValueKey('toast'),
          height: 48,
          child: Text(details.toast.message),
        ),
        child: Column(
          children: [
            if (topBar) const SizedBox(height: 56),
            const Expanded(child: _Host()),
            if (statusLine) const SizedBox(height: 24),
          ],
        ),
      ),
    );
    Rect toast() => tester.getRect(find.byKey(const ValueKey('toast')));
    Rect nav() => tester.getRect(find.byKey(const ValueKey('nav')));
    await _width(tester, 768);
    await tester.pumpWidget(app());
    toaster.currentState!.show(
      const RawToast(message: 'Saved', duration: null),
    );
    await tester.pumpAndSettle();
    // 768 wide a rail, 1440 a sidebar.
    for (final width in [768.0, 1440.0]) {
      await _width(tester, width);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(nav().top, 0);
      expect(nav().bottom, 700);
      expect(toast().bottom, moreOrLessEquals(700 - 16), reason: '$width');
      // It reaches the bottom edge and not the top: no bar for all that.
      await tester.pumpWidget(app(topBar: true));
      await tester.pumpAndSettle();
      expect(nav().top, 56);
      expect(nav().bottom, 700);
      expect(
        toast().bottom,
        moreOrLessEquals(700 - 16),
        reason: 'under a top bar, $width',
      );
      // The top edge and not the bottom, the toasts along the top.
      await tester.pumpWidget(
        app(statusLine: true, alignment: AlignmentDirectional.topCenter),
      );
      await tester.pumpAndSettle();
      expect(nav().top, 0);
      expect(nav().bottom, 676);
      expect(
        toast().top,
        moreOrLessEquals(16),
        reason: 'over a status line, $width',
      );
    }
    await _width(tester, 390);
    await tester.pumpWidget(app(topBar: true));
    await tester.pumpAndSettle();
    expect(nav().bottom, 700);
    expect(toast().bottom, moreOrLessEquals(nav().top - 16), reason: 'a bar');
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
    final text = RawAdaptiveShell.branches(
      destinations: _destinations,
      selectedIndex: 1,
      onDestinationSelected: null,
      destinationBuilder: _destination,
      navigationBuilder: _navigationOf,
      branches: [for (final _ in _destinations) (context) => const SizedBox()],
      backBehavior: RawBranchBackBehavior.history,
      mode: RawNavigationMode.rail,
      modeForWidth: RawNavigationMode.fromWidth,
      showNavigation: false,
      dampingRatio: .5,
    ).toDiagnosticsNode().toStringDeep();
    for (final s in [
      'destinations: [Home, Mail, Settings]',
      'selectedIndex: 1',
      'branches: 3',
      'backBehavior: history',
      'bar hidden on push',
      'mode: rail',
      'has modeForWidth',
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
