// The app shell: Neumorphism's raised tab bar under 1024 wide and its pilaster from there, each place keeping its own
// pages; a page pushed in a place keeps the pilaster beside it and takes the tab bar away; toasts stand clear of the bar.

import 'dart:ui' show SemanticsRole;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

const _places = [
  RawNavigationDestination(label: 'Books', icon: NeumorphicGlyphs.file),
  RawNavigationDestination(label: 'Search', icon: NeumorphicGlyphs.search),
  RawNavigationDestination(label: 'Settings', icon: NeumorphicGlyphs.settings),
];

Future<List<GlobalKey<NavigatorState>>> _pump(
  WidgetTester t, {
  double width = 390,
  TextDirection direction = TextDirection.ltr,
  Brightness brightness = Brightness.light,
}) async {
  t.view.physicalSize = Size(width, 844);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final keys = [for (final _ in _places) GlobalKey<NavigatorState>()];
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, page) => Directionality(
        textDirection: direction,
        child: NeumorphicHost(brightness: brightness, child: page!),
      ),
      home: NeumorphicAppShell(
        header: const NeumorphicBrandRow('Shelf'),
        navigatorKeys: keys,
        destinations: _places,
        branches: [
          for (final place in _places)
            (context) => NeumorphicScaffold(
              body: Center(child: Text('${place.label} root')),
            ),
        ],
      ),
    ),
  );
  await t.pumpAndSettle();
  return keys;
}

void _push(GlobalKey<NavigatorState> key) => key.currentState!.push(
  PageRouteBuilder<void>(
    pageBuilder: (context, _, _) =>
        const NeumorphicScaffold(body: Center(child: Text('Dune'))),
  ),
);

void main() {
  testWidgets('a phone: the tab bar along the foot, no pilaster', (t) async {
    await _pump(t);
    expect(find.text('Shelf'), findsNothing);
    final root = t.getRect(find.text('Books root'));
    for (final place in _places) {
      final r = t.getRect(find.text(place.label));
      expect(r.top, greaterThan(844 - 100), reason: place.label);
      expect(r.top, greaterThan(root.bottom), reason: place.label);
    }
    await t.tap(find.text('Search'));
    await t.pumpAndSettle();
    expect(find.text('Search root'), findsOneWidget);
  });

  testWidgets('a phone: the places are tabs, the shown one selected', (
    t,
  ) async {
    final semantics = t.ensureSemantics();
    await _pump(t);
    expect(
      t.getSemantics(find.text('Books')),
      matchesSemantics(
        label: 'Books\nTab 1 of 3',
        isSelected: true,
        hasSelectedState: true,
        isFocusable: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
        hasFocusAction: true,
        role: SemanticsRole.tab,
      ),
    );
    semantics.dispose();
  });

  for (final (width, bar) in [(1023.0, true), (1024.0, false)]) {
    testWidgets('at ${width.round()} the ${bar ? 'tab bar' : 'pilaster'}', (
      t,
    ) async {
      await _pump(t, width: width);
      expect(find.text('Shelf'), bar ? findsNothing : findsOneWidget);
    });
  }

  for (final direction in TextDirection.values) {
    testWidgets('a desktop, ${direction.name}: the pilaster at the start, '
        'its own width', (t) async {
      await _pump(t, width: 1440, direction: direction);
      const side = neumorphicPilasterWidth;
      final page = t.getRect(find.text('Books root'));
      final link = t.getRect(find.text('Books'));
      if (direction == TextDirection.ltr) {
        expect(link.right, lessThanOrEqualTo(side));
        expect(page.center.dx, moreOrLessEquals(side + (1440 - side) / 2));
      } else {
        expect(link.left, greaterThanOrEqualTo(1440 - side));
        expect(page.center.dx, moreOrLessEquals((1440 - side) / 2));
      }
      expect(link.top, lessThan(200));
    });
  }

  testWidgets('a phone: a pushed page takes the tab bar away, back brings '
      'it back', (t) async {
    final keys = await _pump(t);
    _push(keys[0]);
    await t.pumpAndSettle();
    expect(find.text('Dune'), findsOneWidget);
    expect(find.text('Search').hitTestable(), findsNothing);
    keys[0].currentState!.pop();
    await t.pumpAndSettle();
    expect(find.text('Search').hitTestable(), findsOneWidget);
  });

  testWidgets('a desktop: a pushed page keeps the pilaster beside it', (
    t,
  ) async {
    final keys = await _pump(t, width: 1440);
    _push(keys[0]);
    await t.pumpAndSettle();
    expect(find.text('Dune'), findsOneWidget);
    expect(find.text('Search').hitTestable(), findsOneWidget);
    expect(
      t.getRect(find.text('Dune')).left,
      greaterThan(neumorphicPilasterWidth),
    );
  });

  testWidgets('each place keeps its own pages', (t) async {
    final keys = await _pump(t, width: 1440);
    _push(keys[0]);
    await t.pumpAndSettle();
    await t.tap(find.text('Search'));
    await t.pumpAndSettle();
    expect(find.text('Search root'), findsOneWidget);
    expect(find.text('Dune'), findsNothing);
    await t.tap(find.text('Books'));
    await t.pumpAndSettle();
    expect(find.text('Dune'), findsOneWidget);
  });

  testWidgets('a toast stands clear of the tab bar', (t) async {
    await _pump(t);
    showNeumorphicToast(t.element(find.text('Books root')), message: 'Saved');
    await t.pumpAndSettle();
    final toast = t.getRect(find.text('Saved'));
    expect(toast.bottom, lessThan(t.getRect(find.text('Books')).top));
    await t.pump(const Duration(seconds: 30));
    await t.pumpAndSettle();
  });

  testWidgets("by night the bar's shoulders stand on the wall", (t) async {
    await _pump(t, brightness: Brightness.dark);
    final wall = NeumorphicThemeData.preset(
      NeumorphicThemeData.palettes.first.id,
      Brightness.dark,
    ).colors.ground;
    // Nothing between the host's wall and the bar paints the app's own
    // canvas: the box under the shell is the host's.
    final grounds = t
        .widgetList<ColoredBox>(
          find.ancestor(
            of: find.byType(NeumorphicAppShell),
            matching: find.byType(ColoredBox),
          ),
        )
        .map((b) => b.color);
    expect(grounds.first, wall);
  });
}
