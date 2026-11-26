// The shell's modes by width, its header across the top, and its bar that
// steps away under a page pushed on a branch.
import 'dart:ui' show Tristate;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_harness.dart';

const List<RawNavigationDestination> _destinations = [
  RawNavigationDestination(label: 'Books', icon: IconData(0xe318)),
  RawNavigationDestination(label: 'Shelves', icon: IconData(0xe158)),
  RawNavigationDestination(label: 'Settings', icon: IconData(0xe57f)),
];

RawNavigationDetails? _details;

Widget _destination(
  BuildContext context,
  RawNavigationDestination destination,
  RawDestinationDetails details,
) => SizedBox(
  key: ValueKey('dest ${destination.label}'),
  height: 48,
  child: Center(child: Text(destination.label)),
);

Widget _navigation(BuildContext context, RawNavigationDetails details) {
  _details = details;
  return switch (details.mode) {
    RawNavigationMode.bar => SizedBox(
      key: const ValueKey('nav'),
      height: 64,
      child: Row(
        children: [for (final d in details.destinations) Expanded(child: d)],
      ),
    ),
    // A header: the app's name, then the destinations in a group.
    RawNavigationMode.top => SizedBox(
      key: const ValueKey('nav'),
      height: 56,
      child: Row(
        children: [
          const SizedBox(width: 120, child: Text('Shelf')),
          Expanded(
            child: details.group(
              Row(
                children: [
                  for (final d in details.destinations) Expanded(child: d),
                ],
              ),
            ),
          ),
        ],
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
  };
}

RawNavigationMode _barOrTop(double width) =>
    width < 600 ? RawNavigationMode.bar : RawNavigationMode.top;

Future<void> _size(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pump();
}

class _Shell extends StatefulWidget {
  const _Shell({this.modeForWidth, this.hideBarOnPush = true, this.keys});

  final RawNavigationModeForWidth? modeForWidth;
  final bool hideBarOnPush;
  final List<GlobalKey<NavigatorState>>? keys;

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  int selected = 0;

  @override
  Widget build(BuildContext context) => RawAdaptiveShell.branches(
    modeForWidth: widget.modeForWidth,
    hideBarOnPush: widget.hideBarOnPush,
    navigatorKeys: widget.keys,
    destinations: _destinations,
    selectedIndex: selected,
    onDestinationSelected: (i) => setState(() => selected = i),
    destinationBuilder: _destination,
    navigationBuilder: _navigation,
    branches: [
      for (final d in _destinations)
        (context) => Column(
          key: ValueKey('${d.label} root'),
          children: [
            Builder(
              builder: (context) => Text(
                '${d.label} top inset ${MediaQuery.paddingOf(context).top}',
              ),
            ),
            Focus(
              debugLabel: '${d.label} field',
              child: const SizedBox(width: 44, height: 44),
            ),
          ],
        ),
    ],
  );
}

bool _focusedOn(WidgetTester tester, String label) =>
    tester
        .getSemantics(find.byKey(ValueKey('dest $label')))
        .getSemanticsData()
        .flagsCollection
        .isFocused ==
    Tristate.isTrue;

void main() {
  setUp(() => _details = null);

  test('the modes by width: Material\'s classes, or the look\'s own', () {
    List<RawNavigationMode> modes(RawNavigationModeForWidth of) => [
      for (final w in [390.0, 600, 900, 1023, 1024, 1199, 1200])
        of(w.toDouble()),
    ];
    const bar = RawNavigationMode.bar;
    const rail = RawNavigationMode.rail;
    const sidebar = RawNavigationMode.sidebar;
    expect(modes(RawNavigationMode.fromWidth), [
      bar, rail, rail, rail, rail, rail, sidebar, //
    ]);
    expect(modes((w) => RawNavigationMode.fromWidth(w, sidebar: 1024)), [
      bar, rail, rail, rail, sidebar, sidebar, sidebar, //
    ]);
    expect(modes((w) => RawNavigationMode.fromWidth(w, rail: 640)), [
      bar, bar, rail, rail, rail, rail, sidebar, //
    ]);
    expect(RawNavigationMode.top.isHorizontal, isTrue);
    expect(RawNavigationMode.bar.isHorizontal, isTrue);
    expect(RawNavigationMode.rail.isHorizontal, isFalse);
  });

  for (final direction in TextDirection.values) {
    testWidgets('a header across the top, ${direction.name}: the body below '
        'it without the top inset, a tab bar of its destinations, Left and '
        'Right between them, F6 to the body', (tester) async {
      final semantics = tester.ensureSemantics();
      await _size(tester, 1440);
      await tester.pumpWidget(
        harness(
          const MediaQuery(
            data: MediaQueryData(
              size: Size(1440, 700),
              padding: EdgeInsets.only(top: 24),
            ),
            child: _Shell(modeForWidth: _barOrTop),
          ),
          textDirection: direction,
        ),
      );
      expect(_details!.mode, RawNavigationMode.top);
      expect(
        tester.getRect(find.byKey(const ValueKey('nav'))),
        const Rect.fromLTWH(0, 0, 1440, 56),
      );
      final body = tester.getRect(find.byKey(const ValueKey('Books root')));
      expect(body.top, greaterThanOrEqualTo(56), reason: 'below the header');
      expect(find.text('Books top inset 0.0'), findsOneWidget);
      final tab = tester.getSemantics(find.byKey(const ValueKey('dest Books')));
      expect(tab.getSemanticsData().role, SemanticsRole.tab);
      expect(tab.parent!.role, SemanticsRole.tabBar);
      final ltr = direction == TextDirection.ltr;
      expect(
        tester.getRect(find.byKey(const ValueKey('dest Books'))).left <
            tester.getRect(find.byKey(const ValueKey('dest Shelves'))).left,
        ltr,
      );
      // The page's field, then the header's one stop.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(_focusedOn(tester, 'Books'), isTrue);
      await tester.sendKeyEvent(
        ltr ? LogicalKeyboardKey.arrowRight : LogicalKeyboardKey.arrowLeft,
      );
      await tester.pumpAndSettle();
      expect(_focusedOn(tester, 'Shelves'), isTrue, reason: 'on, mirrored');
      await tester.sendKeyEvent(LogicalKeyboardKey.f6);
      await tester.pumpAndSettle();
      expect(_focusedOn(tester, 'Shelves'), isFalse, reason: 'F6: the body');
      semantics.dispose();
    });
  }

  testWidgets('the look\'s widths pick the mode: a bar on a phone, the '
      'header wider', (tester) async {
    await _size(tester, 390);
    await tester.pumpWidget(harness(const _Shell(modeForWidth: _barOrTop)));
    expect(_details!.mode, RawNavigationMode.bar);
    expect(tester.getRect(find.byKey(const ValueKey('nav'))).bottom, 700);
    await _size(tester, 800);
    expect(_details!.mode, RawNavigationMode.top);
    expect(tester.getRect(find.byKey(const ValueKey('nav'))).top, 0);
  });

  testWidgets('toasts along the top stand below a header; along the bottom '
      'the header keeps nothing', (tester) async {
    await _size(tester, 1440);
    final toaster = GlobalKey<RawToasterState>();
    Widget app(AlignmentGeometry alignment) => harness(
      RawToaster(
        key: toaster,
        alignment: alignment,
        toastBuilder: (context, details) => SizedBox(
          key: const ValueKey('toast'),
          height: 48,
          child: Text(details.toast.message),
        ),
        child: const _Shell(modeForWidth: _barOrTop),
      ),
    );
    await tester.pumpWidget(app(AlignmentDirectional.topCenter));
    toaster.currentState!.show(
      const RawToast(message: 'Saved', duration: null),
    );
    await tester.pumpAndSettle();
    Rect toast() => tester.getRect(find.byKey(const ValueKey('toast')));
    expect(toast().top, moreOrLessEquals(56 + 16));
    expect(toast().center.dx, moreOrLessEquals(720), reason: 'centred');
    await tester.pumpWidget(app(AlignmentDirectional.bottomCenter));
    await tester.pumpAndSettle();
    expect(toast().bottom, moreOrLessEquals(700 - 16));
    // Under a strip of the app's own, the header reaches no edge: still a
    // header.
    await tester.pumpWidget(
      harness(
        RawToaster(
          key: toaster,
          alignment: AlignmentDirectional.topCenter,
          toastBuilder: (context, details) => SizedBox(
            key: const ValueKey('toast'),
            height: 48,
            child: Text(details.toast.message),
          ),
          child: const Column(
            children: [
              SizedBox(height: 24),
              Expanded(child: _Shell(modeForWidth: _barOrTop)),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(toast().top, moreOrLessEquals(24 + 56 + 16));
  });

  group('a page pushed on a branch', () {
    testWidgets('takes the bar\'s room as the bar springs away, and gives it '
        'back as it pops', (tester) async {
      await _size(tester, 390);
      final keys = [for (final _ in _destinations) GlobalKey<NavigatorState>()];
      await tester.pumpWidget(harness(_Shell(keys: keys)));
      expect(_details!.pushed, isFalse);
      final barTop = tester.getRect(find.byKey(const ValueKey('nav'))).top;
      expect(barTop, 636);
      keys[0].currentState!
          .push(
            PageRouteBuilder<void>(
              pageBuilder: (context, _, _) =>
                  const SizedBox.expand(key: ValueKey('detail')),
            ),
          )
          .ignore();
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      expect(_details!.pushed, isTrue);
      final moving = _details!.visibility.value;
      expect(moving, inExclusiveRange(0, 1), reason: 'on its spring');
      await tester.pumpAndSettle();
      expect(_details!.visibility.value, 0);
      expect(tester.getRect(find.byKey(const ValueKey('nav'))).top, 700);
      expect(tester.getSize(find.byKey(const ValueKey('detail'))).height, 700);
      // Hidden, the bar takes no focus.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(_focusedOn(tester, 'Books'), isFalse);
      expect(await tester.binding.handlePopRoute(), isTrue);
      await tester.pumpAndSettle();
      expect(_details!.pushed, isFalse);
      expect(tester.getRect(find.byKey(const ValueKey('nav'))).top, 636);
    });

    testWidgets('keeps the bar under it with hideBarOnPush off, as '
        'Cupertino\'s tab scaffold does', (tester) async {
      await _size(tester, 390);
      final keys = [for (final _ in _destinations) GlobalKey<NavigatorState>()];
      await tester.pumpWidget(
        harness(_Shell(keys: keys, hideBarOnPush: false)),
      );
      keys[0].currentState!
          .push(
            PageRouteBuilder<void>(
              pageBuilder: (context, _, _) => const SizedBox.expand(),
            ),
          )
          .ignore();
      await tester.pumpAndSettle();
      expect(_details!.pushed, isTrue);
      expect(tester.getRect(find.byKey(const ValueKey('nav'))).top, 636);
    });

    for (final (width, mode) in [
      (768.0, RawNavigationMode.rail),
      (1440.0, RawNavigationMode.sidebar),
      (1440.0, RawNavigationMode.top),
    ]) {
      testWidgets('keeps the ${mode.name} beside it', (tester) async {
        await _size(tester, width);
        final keys = [
          for (final _ in _destinations) GlobalKey<NavigatorState>(),
        ];
        await tester.pumpWidget(
          harness(
            _Shell(
              keys: keys,
              modeForWidth: mode == RawNavigationMode.top ? _barOrTop : null,
            ),
          ),
        );
        expect(_details!.mode, mode);
        final before = tester.getRect(find.byKey(const ValueKey('nav')));
        keys[0].currentState!
            .push(
              PageRouteBuilder<void>(
                pageBuilder: (context, _, _) => const SizedBox.expand(),
              ),
            )
            .ignore();
        await tester.pumpAndSettle();
        expect(_details!.pushed, isTrue);
        expect(tester.getRect(find.byKey(const ValueKey('nav'))), before);
      });
    }

    testWidgets('on another branch leaves the selected one\'s bar', (
      tester,
    ) async {
      await _size(tester, 390);
      final keys = [for (final _ in _destinations) GlobalKey<NavigatorState>()];
      await tester.pumpWidget(harness(_Shell(keys: keys)));
      await tester.tap(find.text('Shelves'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Books'));
      await tester.pumpAndSettle();
      keys[1].currentState!
          .push(
            PageRouteBuilder<void>(
              pageBuilder: (context, _, _) => const SizedBox.expand(),
            ),
          )
          .ignore();
      await tester.pumpAndSettle();
      expect(_details!.pushed, isFalse, reason: 'Books is selected');
      expect(tester.getRect(find.byKey(const ValueKey('nav'))).top, 636);
      await tester.tap(find.text('Shelves'));
      await tester.pumpAndSettle();
      expect(_details!.pushed, isTrue, reason: 'Shelves has its page');
      expect(tester.getRect(find.byKey(const ValueKey('nav'))).top, 700);
    });
  });

  testWidgets('over the app\'s own body nothing is pushed: showNavigation '
      'says', (tester) async {
    await _size(tester, 390);
    await tester.pumpWidget(
      harness(
        RawAdaptiveShell(
          destinations: _destinations,
          selectedIndex: 0,
          onDestinationSelected: (_) {},
          destinationBuilder: _destination,
          navigationBuilder: _navigation,
          body: Navigator(
            onGenerateInitialRoutes: (navigator, name) => [
              PageRouteBuilder<void>(
                pageBuilder: (context, _, _) => const Text('root'),
              ),
              PageRouteBuilder<void>(
                pageBuilder: (context, _, _) => const Text('detail'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(_details!.pushed, isFalse);
    expect(tester.getRect(find.byKey(const ValueKey('nav'))).top, 636);
  });

  for (final (edge, direction, left, right) in [
    (RawKeepClearEdge.start, TextDirection.ltr, 200.0, 0.0),
    (RawKeepClearEdge.start, TextDirection.rtl, 0.0, 200.0),
    (RawKeepClearEdge.end, TextDirection.ltr, 0.0, 200.0),
    (RawKeepClearEdge.end, TextDirection.rtl, 200.0, 0.0),
  ]) {
    testWidgets('a part kept along the ${edge.name}, ${direction.name}, keeps '
        'the toasts beside it, wherever it stands up and down', (tester) async {
      await _size(tester, 1000);
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
            // The part at the left or the right, whatever the direction.
            child: Stack(
              children: [
                Positioned(
                  left: left > 0 ? 0 : null,
                  right: right > 0 ? 0 : null,
                  top: 100,
                  width: 200,
                  height: 300,
                  child: RawToasterKeepClear(
                    edge: edge,
                    child: const SizedBox.expand(),
                  ),
                ),
              ],
            ),
          ),
          textDirection: direction,
        ),
      );
      toaster.currentState!.show(
        const RawToast(message: 'Saved', duration: null),
      );
      await tester.pumpAndSettle();
      final toast = tester.getRect(find.byKey(const ValueKey('toast')));
      expect(
        toast.center.dx,
        moreOrLessEquals(left + (1000 - left - right) / 2),
      );
      expect(toast.bottom, moreOrLessEquals(700 - 16), reason: 'no band');
    });
  }
}
