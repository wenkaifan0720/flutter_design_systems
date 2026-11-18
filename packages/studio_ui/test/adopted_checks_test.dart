// The parts Studio moved onto ui_core 0.3.0 (the shell's bank, rail and side
// navigation, a sheet and its finger slot, the rating, the wheel) held to
// ui_core_test's tap-target check: a tap reaches each where a finger or a
// pointer is told it is; and a sheet dragged and let go keeps the keys.
import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';
import 'package:ui_core_test/ui_core_test.dart';

Widget _app(Widget home, {Brightness brightness = Brightness.light}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, app) =>
          StudioHost(brightness: brightness, child: app!),
      home: home,
    );

void _size(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

const _places = [
  StudioDestination(icon: Icon(IconData(0x41)), label: 'Home'),
  StudioDestination(icon: Icon(IconData(0x42)), label: 'Library'),
  StudioDestination(icon: Icon(IconData(0x43)), label: 'Record'),
];

void main() {
  for (final (width, kind, input) in [
    (390.0, StudioNavigationBar, DesignInput.touch),
    (800.0, StudioNavigationRail, DesignInput.pointer),
    (1440.0, StudioSideNavigation, DesignInput.pointer),
  ]) {
    testWidgets("at $width the shell's places take ${input.name} taps", (
      tester,
    ) async {
      _size(tester, Size(width, 900));
      await tester.pumpWidget(
        _app(
          StudioScaffold(
            destinations: _places,
            selectedIndex: 0,
            onDestinationSelected: (_) {},
            body: const SizedBox.expand(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(kind), findsOneWidget);
      DesignTapTargetCheck(
        look: 'Studio',
        input: input,
      ).check(tester.element(find.byType(kind))).verify();
    });
  }

  testWidgets("a sheet's finger slot and close key take a finger's taps", (
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
      showStudioBottomSheet<void>(
        context: page,
        title: 'Export',
        builder: (context) => const Text('MP3, 128 kbps'),
      ),
    );
    await tester.pumpAndSettle();
    const DesignTapTargetCheck(
      look: 'Studio',
      input: DesignInput.touch,
    ).check(tester.element(find.byType(StudioSheet))).verify();
  });

  testWidgets("a rating's lenses take a finger's taps", (tester) async {
    _size(tester, const Size(390, 844));
    await tester.pumpWidget(
      _app(
        Center(
          child: StudioRating(
            value: 3,
            semanticLabel: 'Your rating',
            onChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    const DesignTapTargetCheck(
      look: 'Studio',
      input: DesignInput.touch,
    ).check(tester.element(find.byType(StudioRating))).verify();
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
      showStudioBottomSheet<void>(
        context: page,
        title: 'Export',
        builder: (context) => const Text('MP3, 128 kbps'),
      ),
    );
    await tester.pumpAndSettle();
    // Held by its finger slot, a little way down, then let go: it settles
    // back up.
    final slot = tester.getCenter(find.bySemanticsLabel('Drag handle'));
    final drag = await tester.startGesture(slot, kind: PointerDeviceKind.mouse);
    for (var i = 0; i < 8; i++) {
      await drag.moveBy(const Offset(0, 6));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await drag.up();
    await tester.pumpAndSettle();
    expect(find.text('MP3, 128 kbps'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('MP3, 128 kbps'), findsNothing);
  });
}
