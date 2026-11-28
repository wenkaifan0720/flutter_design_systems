// On a phone a bottom sheet stands on the app shell's strip, with and without
// a home-indicator inset: it never covers the strip's places, the strip keeps
// the inset, a press on the strip closes the sheet and a drag down does too;
// its title names the route.
// On a desk the same call still opens a window.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import 'support.dart';

const _places = [
  RetroDesktopNavItem(
    label: 'Books',
    short: 'Books',
    icon: RetroDesktopGlyphs.folder,
  ),
  RetroDesktopNavItem(
    label: 'Add a book',
    short: 'Add',
    icon: RetroDesktopGlyphs.plus,
  ),
  RetroDesktopNavItem(
    label: 'Settings',
    short: 'Settings',
    icon: RetroDesktopGlyphs.settings,
  ),
];

final _sheet = find.byType(RetroDesktopBottomSheet);

// The sheet's panel: inside the room the screen's inset leaves.
Rect _panel(WidgetTester tester) => tester.getRect(
  find.descendant(of: _sheet, matching: find.byType(Align)).first,
);

ModalRoute<Object?>? _route(WidgetTester tester) =>
    ModalRoute.of(tester.element(find.text('By title')));

Future<List<int>> _pump(
  WidgetTester tester, {
  required double width,
  double inset = 0,
  bool shell = true,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  tester.view.padding = FakeViewPadding(bottom: inset);
  addTearDown(tester.view.reset);
  final chosen = <int>[];
  Widget page(String title) => RetroDesktopScaffold(
    appBar: RetroDesktopAppBar(title: title),
    body: Builder(
      builder: (context) => RetroDesktopButton(
        'Sort',
        onPressed: () => showRetroDesktopBottomSheet<void>(
          context,
          builder: (context) => const RetroDesktopBottomSheet(
            title: 'Sort books',
            child: Text('By title'),
          ),
        ),
      ),
    ),
  );
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, child) => RetroDesktopHost(child: child!),
      home: shell
          ? RetroDesktopAppShell.branches(
              brand: 'Shelf',
              destinations: _places,
              selectedIndex: 0,
              onDestinationSelected: chosen.add,
              branches: [
                for (final place in _places) (context) => page(place.label),
              ],
            )
          : page('Books'),
    ),
  );
  await tester.pumpAndSettle();
  return chosen;
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('Sort').first);
  await tester.pumpAndSettle();
}

// The strip: the nearest box across the whole screen around a place's words.
Rect _strip(WidgetTester tester) {
  final width = tester.view.physicalSize.width;
  for (final element
      in find
          .ancestor(
            of: find.text('Settings'),
            matching: find.byWidgetPredicate((_) => true),
          )
          .evaluate()) {
    final box = element.renderObject;
    if (box is RenderBox && box.hasSize && box.size.width == width) {
      return box.localToGlobal(Offset.zero) & box.size;
    }
  }
  throw StateError('no strip');
}

void main() {
  setUpAll(loadRetroDesktopFonts);

  for (final inset in [0.0, 34.0]) {
    testWidgets(
      'on a phone a sheet stands on the strip (inset ${inset.toInt()})',
      (tester) async {
        await _pump(tester, width: 390, inset: inset);
        final strip = _strip(tester);
        expect(strip.bottom, 844, reason: 'the strip keeps the inset');
        await _open(tester);
        expect(_strip(tester), strip, reason: 'the strip stays put');
        expect(_route(tester), isA<RawBottomSheetRoute<void>>());
        final sheet = _panel(tester);
        expect(sheet.bottom, strip.top);
        expect(sheet.left, 0);
        expect(sheet.right, 390);
        for (final place in ['Books', 'Add', 'Settings']) {
          final words = tester.getRect(
            find
                .descendant(
                  of: find.byType(RetroDesktopAppShell),
                  matching: find.text(place),
                )
                .last,
          );
          expect(words.top, greaterThanOrEqualTo(sheet.bottom), reason: place);
        }
      },
    );
  }

  testWidgets('a press on the strip closes the sheet and keeps the place', (
    tester,
  ) async {
    final chosen = await _pump(tester, width: 390, inset: 34);
    await _open(tester);
    await tester.tapAt(tester.getCenter(find.text('Settings').last));
    await tester.pumpAndSettle();
    expect(_sheet, findsNothing);
    expect(chosen, isEmpty);
  });

  testWidgets('a drag down closes the sheet', (tester) async {
    await _pump(tester, width: 390);
    await _open(tester);
    await tester.drag(find.text('Sort books'), const Offset(0, 300));
    await tester.pumpAndSettle();
    expect(_sheet, findsNothing);
  });

  testWidgets("the sheet's title names its route", (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, width: 390);
    await _open(tester);
    expect(
      find.semantics.byPredicate(
        (node) =>
            node.label == 'Sort books' &&
            node.getSemanticsData().flagsCollection.namesRoute,
      ),
      findsOne,
    );
    semantics.dispose();
  });

  testWidgets('with no strip the sheet stands above the inset', (tester) async {
    await _pump(tester, width: 390, inset: 34, shell: false);
    await _open(tester);
    expect(_panel(tester).bottom, 844 - 34);
  });

  testWidgets('on a desk the same call opens a window', (tester) async {
    await _pump(tester, width: 1440, shell: false);
    await _open(tester);
    expect(_route(tester), isNot(isA<RawBottomSheetRoute<void>>()));
    expect(tester.getRect(find.text('Sort books')).top, lessThan(844 / 2));
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
}
