// Verify tap targets and keyboard focus after dismissing a dragged sheet.
import 'dart:async';

import 'package:appliance_ui/appliance_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart';

Widget _app(Widget home) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, app) =>
      ApplianceHost(brightness: Brightness.light, child: app!),
  home: home,
);

void _size(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

const _places = [
  ApplianceDestination(icon: Icons.home_outlined, label: 'Home'),
  ApplianceDestination(icon: Icons.shopping_bag_outlined, label: 'Shop'),
  ApplianceDestination(icon: Icons.settings_outlined, label: 'Settings'),
];

void main() {
  testWidgets("the rail's places take a pointer's taps", (tester) async {
    _size(tester, const Size(900, 700));
    await tester.pumpWidget(
      _app(
        ApplianceScaffold(
          destinations: _places,
          selectedIndex: 0,
          onSelected: (_) {},
          body: const SizedBox.expand(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ApplianceNavigationRail), findsOneWidget);
    const DesignTapTargetCheck(
      look: 'Appliance',
      input: RawInput.pointer,
    ).check(tester.element(find.byType(ApplianceNavigationRail))).verify();
  });

  testWidgets("a sheet's grip and keys take a finger's taps", (tester) async {
    _size(tester, const Size(390, 844));
    late BuildContext page;
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) {
            page = context;
            return const SizedBox.expand();
          },
        ),
      ),
    );
    unawaited(
      showApplianceBottomSheet<void>(
        context: page,
        title: 'Filter',
        footer: [ApplianceButton.filled('Show 12', onPressed: () {})],
        builder: (context) => const Text('In stock only'),
      ),
    );
    await tester.pumpAndSettle();
    const DesignTapTargetCheck(
      look: 'Appliance',
      input: RawInput.touch,
    ).check(tester.element(find.byType(ApplianceSheet))).verify();
  });

  testWidgets("a rating's stars take a finger's taps", (tester) async {
    _size(tester, const Size(390, 844));
    await tester.pumpWidget(
      _app(Center(child: ApplianceRating(value: 3, onChanged: (_) {}))),
    );
    await tester.pumpAndSettle();
    const DesignTapTargetCheck(
      look: 'Appliance',
      input: RawInput.touch,
    ).check(tester.element(find.byType(ApplianceRating))).verify();
  });

  testWidgets('a sheet dragged and let go keeps the keys: Escape closes it', (
    tester,
  ) async {
    _size(tester, const Size(390, 844));
    late BuildContext page;
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) {
            page = context;
            return const SizedBox.expand();
          },
        ),
      ),
    );
    unawaited(
      showApplianceBottomSheet<void>(
        context: page,
        title: 'Filter',
        builder: (context) => const Text('In stock only'),
      ),
    );
    await tester.pumpAndSettle();
    // Held by its grip, two fifths of its height down, then let go: it
    // settles back up.
    final grip = tester.getCenter(find.bySemanticsLabel('Drag handle'));
    final drag = await tester.startGesture(grip, kind: PointerDeviceKind.mouse);
    for (var i = 0; i < 8; i++) {
      await drag.moveBy(const Offset(0, 6));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await drag.up();
    await tester.pumpAndSettle();
    expect(find.text('In stock only'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('In stock only'), findsNothing);
  });

  testWidgets("a router's sheet page dragged and let go keeps the keys: "
      'Escape closes it', (tester) async {
    _size(tester, const Size(390, 844));
    final pages = <Page<void>>[
      const MaterialPage<void>(key: ValueKey('home'), child: SizedBox.expand()),
    ];
    late StateSetter update;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return Navigator(
              pages: List.of(pages),
              onDidRemovePage: (page) => setState(() => pages.remove(page)),
            );
          },
        ),
      ),
    );
    update(
      () => pages.add(
        const ApplianceSheetPage<void>(
          key: ValueKey('filter'),
          child: Center(child: Text('In stock only')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('In stock only'), findsOneWidget);
    final drag = await tester.startGesture(
      tester.getCenter(find.text('In stock only')),
      kind: PointerDeviceKind.mouse,
    );
    for (var i = 0; i < 8; i++) {
      await drag.moveBy(const Offset(0, 6));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await drag.up();
    await tester.pumpAndSettle();
    expect(find.text('In stock only'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('In stock only'), findsNothing);
    expect(pages, hasLength(1));
  });
}
