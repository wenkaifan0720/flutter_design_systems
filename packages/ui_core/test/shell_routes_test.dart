// What a page pushed over the shell's body, or over the shell, leaves of
// the navigation, the toasts' clearance and a popover's side.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_harness.dart';

const List<RawNavigationDestination> _destinations = [
  RawNavigationDestination(label: 'Books', icon: IconData(0xe318)),
  RawNavigationDestination(label: 'Shelves', icon: IconData(0xe158)),
  RawNavigationDestination(label: 'Settings', icon: IconData(0xe57f)),
];

Widget _destination(
  BuildContext context,
  RawNavigationDestination destination,
  RawDestinationDetails details,
) => SizedBox(height: 48, child: Center(child: Text(destination.label)));

Widget _navigation(BuildContext context, RawNavigationDetails details) =>
    switch (details.mode) {
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
      _ => SizedBox(
        key: const ValueKey('nav'),
        width: 240,
        child: Column(children: details.destinations),
      ),
    };

Route<void> _page(String name) =>
    PageRouteBuilder<void>(pageBuilder: (context, _, _) => Text('$name page'));

Future<void> _size(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pump();
}

// Every destination is in the semantics tree, each once.
void _expectNavigation(String reason) {
  for (final (i, d) in _destinations.indexed) {
    expect(
      find.bySemanticsLabel('${d.label}\nTab ${i + 1} of 3'),
      findsOneWidget,
      reason: reason,
    );
  }
}

void main() {
  const widths = {
    RawNavigationMode.bar: 390.0,
    RawNavigationMode.rail: 768.0,
    RawNavigationMode.sidebar: 1440.0,
  };

  for (final mode in widths.keys) {
    for (final branches in [false, true]) {
      for (final direction in TextDirection.values) {
        final form = branches ? 'branches' : 'its own navigator';
        testWidgets('a ${mode.name}: a page pushed in the body ($form, '
            '${direction.name}) leaves the navigation in the semantics tree, '
            'and so does its pop', (tester) async {
          final semantics = tester.ensureSemantics();
          await _size(tester, widths[mode]!);
          final inner = GlobalKey<NavigatorState>();
          final keys = [
            for (final _ in _destinations) GlobalKey<NavigatorState>(),
          ];
          final shell = branches
              ? RawAdaptiveShell.branches(
                  mode: mode,
                  destinations: _destinations,
                  selectedIndex: 0,
                  onDestinationSelected: (_) {},
                  destinationBuilder: _destination,
                  navigationBuilder: _navigation,
                  navigatorKeys: keys,
                  branches: [
                    for (final d in _destinations)
                      (context) => Text('${d.label} root'),
                  ],
                )
              : RawAdaptiveShell(
                  mode: mode,
                  destinations: _destinations,
                  selectedIndex: 0,
                  onDestinationSelected: (_) {},
                  destinationBuilder: _destination,
                  navigationBuilder: _navigation,
                  body: Navigator(
                    key: inner,
                    onGenerateInitialRoutes: (navigator, name) => [
                      PageRouteBuilder<void>(
                        pageBuilder: (context, _, _) =>
                            const Text('Books root'),
                      ),
                    ],
                  ),
                );
          await tester.pumpWidget(harness(shell, textDirection: direction));
          await tester.pumpAndSettle();
          _expectNavigation('at the root');
          final navigator = branches
              ? keys[0].currentState!
              : inner.currentState!;
          navigator.push(_page('Detail')).ignore();
          await tester.pumpAndSettle();
          expect(find.bySemanticsLabel('Detail page'), findsOneWidget);
          expect(
            find.bySemanticsLabel('Books root'),
            findsNothing,
            reason: 'the page under it is covered',
          );
          _expectNavigation('a page pushed');
          navigator.pop();
          await tester.pumpAndSettle();
          _expectNavigation('popped');
          semantics.dispose();
        });
      }
    }
  }

  testWidgets('a bar kept clear stays clear after a page pushed over it '
      'closes, when the page under it moves as the page closes', (
    tester,
  ) async {
    await _size(tester, 390);
    final toaster = GlobalKey<RawToasterState>();
    final navigator = GlobalKey<NavigatorState>();
    // The page under shrinks a little while the one over it shows, as many
    // looks' page changes move it: its bar is laid out once and not again.
    Route<void> page(Widget child) => PageRouteBuilder<void>(
      pageBuilder: (context, _, _) => child,
      transitionsBuilder: (context, animation, secondary, child) =>
          ScaleTransition(
            scale: Tween<double>(begin: 1, end: .9).animate(secondary),
            child: child,
          ),
    );
    await tester.pumpWidget(
      WidgetsApp(
        navigatorKey: navigator,
        color: const Color(0xFF000000),
        onGenerateRoute: (settings) => page(
          const Column(
            children: [
              Expanded(child: SizedBox.expand()),
              RawToasterKeepClear(
                child: SizedBox(key: ValueKey('dock'), height: 80),
              ),
            ],
          ),
        ),
        builder: (context, child) => Directionality(
          textDirection: TextDirection.ltr,
          child: RawToaster(
            key: toaster,
            toastBuilder: (context, details) => SizedBox(
              key: const ValueKey('toast'),
              height: 48,
              child: Text(details.toast.message),
            ),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    navigator.currentState!.push(page(const SizedBox.expand())).ignore();
    await tester.pumpAndSettle();
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    toaster.currentState!.show(
      const RawToast(message: 'Saved', duration: null),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byKey(const ValueKey('toast'))).bottom,
      moreOrLessEquals(700 - 80 - 16),
      reason: 'above the dock, as before the page was pushed',
    );
  });

  for (final direction in TextDirection.values) {
    testWidgets('at a desk a toast centres on the body beside the sidebar, '
        '${direction.name}', (tester) async {
      await _size(tester, 1440);
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
            child: RawAdaptiveShell(
              destinations: _destinations,
              selectedIndex: 0,
              onDestinationSelected: (_) {},
              destinationBuilder: _destination,
              navigationBuilder: _navigation,
              body: const SizedBox.expand(),
            ),
          ),
          textDirection: direction,
        ),
      );
      toaster.currentState!.show(
        const RawToast(message: 'Saved', duration: null),
      );
      await tester.pumpAndSettle();
      final nav = tester.getRect(find.byKey(const ValueKey('nav')));
      final body = direction == TextDirection.ltr
          ? Rect.fromLTRB(nav.right, 0, 1440, 700)
          : Rect.fromLTRB(0, 0, nav.left, 700);
      final toast = tester.getRect(find.byKey(const ValueKey('toast')));
      expect(toast.center.dx, moreOrLessEquals(body.center.dx));
      expect(toast.left, greaterThanOrEqualTo(body.left + 16));
      expect(toast.right, lessThanOrEqualTo(body.right - 16));
    });
  }

  // A phone 390 x 700 with a dock 80 high kept clear along its foot, and a
  // date field 44 high [top] down opening a calendar [height] high.
  Future<RawPopoverInfo> open(
    WidgetTester tester, {
    required double top,
    required double height,
  }) async {
    late RawPopoverInfo info;
    await _size(tester, 390);
    await tester.pumpWidget(
      harness(
        RawToaster(
          toastBuilder: (context, details) => Text(details.toast.message),
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: top),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: RawPopover(
                      placement: const RawPopoverPlacement(
                        matchAnchorWidth: false,
                        fit: RawPopoverFit.whole,
                      ),
                      semanticLabel: 'Started',
                      anchorBuilder: (context, anchor) => RawButton(
                        onPressed: anchor.toggle,
                        builder: (context, states, _) => const SizedBox(
                          key: ValueKey('field'),
                          width: 200,
                          height: 44,
                        ),
                      ),
                      overlayBuilder: (context, i) {
                        info = i;
                        return SizedBox(
                          key: const ValueKey('calendar'),
                          width: 300,
                          height: height,
                        );
                      },
                    ),
                  ),
                ),
              ),
              const RawToasterKeepClear(
                child: SizedBox(key: ValueKey('dock'), height: 80),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('field')));
    await tester.pumpAndSettle();
    return info;
  }

  testWidgets('a calendar that fits below only over the dock opens above, '
      'where it fits clear of it', (tester) async {
    // Below the field: 700 - 8 - (300 + 44) - 4 = 344 to the window's foot,
    // 264 to the dock's top; above: 300 - 8 - 4 = 288.
    final info = await open(tester, top: 300, height: 280);
    expect(info.side, RawPopoverSide.above);
    final calendar = tester.getRect(find.byKey(const ValueKey('calendar')));
    expect(calendar.bottom, lessThanOrEqualTo(300));
  });

  testWidgets('a calendar that fits below clear of the dock stays below', (
    tester,
  ) async {
    final info = await open(tester, top: 100, height: 280);
    expect(info.side, RawPopoverSide.below);
    expect(
      tester.getRect(find.byKey(const ValueKey('calendar'))).bottom,
      lessThanOrEqualTo(620),
    );
  });

  testWidgets('a calendar that fits on neither side clear of the dock keeps '
      'the rule without it: below, over the dock', (tester) async {
    // Above: 160 - 12 = 148; below to the dock: 620 - 204 - 4 = 412, to the
    // foot 492 - 8 = 484.
    final info = await open(tester, top: 160, height: 460);
    expect(info.side, RawPopoverSide.below);
    expect(
      tester.getSize(find.byKey(const ValueKey('calendar'))).height,
      460,
      reason: 'whole, over the dock rather than cut',
    );
  });

  testWidgets('a toast shown while a page is pushed over the dock comes back '
      'above the dock as the page closes', (tester) async {
    await _size(tester, 390);
    final toaster = GlobalKey<RawToasterState>();
    final navigator = GlobalKey<NavigatorState>();
    Route<void> page(Widget child) => PageRouteBuilder<void>(
      pageBuilder: (context, _, _) => child,
      transitionsBuilder: (context, animation, secondary, child) =>
          ScaleTransition(
            scale: Tween<double>(begin: 1, end: .9).animate(secondary),
            child: child,
          ),
    );
    await tester.pumpWidget(
      WidgetsApp(
        navigatorKey: navigator,
        color: const Color(0xFF000000),
        onGenerateRoute: (settings) => page(
          const Column(
            children: [
              Expanded(child: SizedBox.expand()),
              RawToasterKeepClear(child: SizedBox(height: 80)),
            ],
          ),
        ),
        builder: (context, child) => Directionality(
          textDirection: TextDirection.ltr,
          child: RawToaster(
            key: toaster,
            toastBuilder: (context, details) => SizedBox(
              key: const ValueKey('toast'),
              height: 48,
              child: Text(details.toast.message),
            ),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    navigator.currentState!.push(page(const SizedBox.expand())).ignore();
    await tester.pumpAndSettle();
    toaster.currentState!.show(
      const RawToast(message: 'Saved', duration: null),
    );
    await tester.pumpAndSettle();
    Rect toast() => tester.getRect(find.byKey(const ValueKey('toast')));
    expect(toast().bottom, moreOrLessEquals(700 - 16), reason: 'no dock');
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(toast().bottom, moreOrLessEquals(700 - 80 - 16), reason: 'back');
  });

  testWidgets('a toast shown after a part moved with no layout or paint of its '
      'own keeps clear of where it stands now', (tester) async {
    await _size(tester, 390);
    final toaster = GlobalKey<RawToasterState>();
    final lift = ValueNotifier<double>(0);
    addTearDown(lift.dispose);
    await tester.pumpWidget(
      harness(
        RawToaster(
          key: toaster,
          toastBuilder: (context, details) => SizedBox(
            key: const ValueKey('toast'),
            height: 48,
            child: Text(details.toast.message),
          ),
          child: ValueListenableBuilder<double>(
            valueListenable: lift,
            // The page moves up under a transform; the dock, in a repaint
            // boundary of its own, is neither laid out nor painted again.
            builder: (context, dy, child) =>
                Transform.translate(offset: Offset(0, dy), child: child),
            child: const RepaintBoundary(
              child: Column(
                children: [
                  Expanded(child: SizedBox.expand()),
                  RawToasterKeepClear(child: SizedBox(height: 80)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    lift.value = 200;
    await tester.pumpAndSettle();
    toaster.currentState!.show(
      const RawToast(message: 'Saved', duration: null),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byKey(const ValueKey('toast'))).bottom,
      moreOrLessEquals(700 - 16),
      reason: 'the dock is off its edge now: it keeps nothing',
    );
  });

  testWidgets('a menu from a header kept clear along the top opens right under '
      'its anchor', (tester) async {
    await _size(tester, 1000);
    await tester.pumpWidget(
      harness(
        RawToaster(
          toastBuilder: (context, details) => Text(details.toast.message),
          child: Column(
            children: [
              RawToasterKeepClear(
                edge: RawKeepClearEdge.top,
                child: SizedBox(
                  height: 56,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: RawPopover(
                      placement: const RawPopoverPlacement(
                        matchAnchorWidth: false,
                      ),
                      anchorBuilder: (context, anchor) => RawButton(
                        onPressed: anchor.toggle,
                        builder: (context, states, _) => const SizedBox(
                          key: ValueKey('account'),
                          width: 120,
                          height: 40,
                        ),
                      ),
                      overlayBuilder: (context, info) => const SizedBox(
                        key: ValueKey('menu'),
                        width: 200,
                        height: 160,
                      ),
                    ),
                  ),
                ),
              ),
              const Expanded(child: SizedBox.expand()),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('account')));
    await tester.pumpAndSettle();
    final anchor = tester.getRect(find.byKey(const ValueKey('account')));
    final menu = tester.getRect(find.byKey(const ValueKey('menu')));
    expect(menu.top, moreOrLessEquals(anchor.bottom + 4));
  });
}
