// A dialog raised from a place's first page dims the whole app, the
// phone's tab bar with it: its barrier spans the window, as Fluent's
// dialogs and Material's do (an adopter read the bar as left undimmed).
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

void main() {
  testWidgets("a dialog from a place's first page dims the tab bar", (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            Fluent2Host(brightness: Brightness.light, child: child!),
        home: Fluent2AppShell.branches(
          header: const Text('Shelf'),
          destinations: const [
            Fluent2NavItem(Fluent2Icons.book, 'Books'),
            Fluent2NavItem(Fluent2Icons.settings, 'Settings'),
          ],
          selectedIndex: 0,
          onDestinationSelected: (_) {},
          branches: [
            (context) => Fluent2Scaffold(
              topBar: const Fluent2AppBar(title: 'Books'),
              body: Builder(
                builder: (context) => Fluent2Button(
                  'Delete',
                  onPressed: () => showFluent2Dialog<bool>(
                    context,
                    builder: (context) =>
                        const Fluent2Dialog(title: 'Delete the book?'),
                  ),
                ),
              ),
            ),
            (context) => const Fluent2Scaffold(
              topBar: Fluent2AppBar(title: 'Settings'),
              body: SizedBox(),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    final tab = tester.getCenter(find.text('Settings').last);
    final ground = Offset(tab.dx + 40, tab.dy);
    Future<double> luminance(Offset at) async {
      final image = await captureImage(tester.binding.rootElement!);
      final bytes = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      final i = (at.dy.round() * image.width + at.dx.round()) * 4;
      return Color.fromARGB(
        255,
        bytes.getUint8(i),
        bytes.getUint8(i + 1),
        bytes.getUint8(i + 2),
      ).computeLuminance();
    }

    final before = (await tester.runAsync(() => luminance(ground)))!;
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete the book?'), findsOneWidget);
    final dimming = [
      for (final e in find.byType(ModalBarrier).evaluate())
        if (((e.widget as ModalBarrier).color?.a ?? 0) > 0) e,
    ];
    expect(dimming, hasLength(1));
    final barrier = tester.getRect(
      find.byElementPredicate((e) => e == dimming.single),
    );
    expect(barrier, const Rect.fromLTWH(0, 0, 390, 844));
    expect(barrier.contains(tab), isTrue);
    final after = (await tester.runAsync(() => luminance(ground)))!;
    expect(after, lessThan(before * 0.7));
  });
}
