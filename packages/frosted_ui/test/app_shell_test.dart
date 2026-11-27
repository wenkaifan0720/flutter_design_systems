// The app shell: Frosted's glass tab bar under 1024 wide and its sidebar from there, each place keeping its own pages;
// a page pushed in a place keeps the sidebar beside it and takes the tab bar away; toasts stand clear of the bar.

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';

const _places = [
  RawNavigationDestination(label: 'Books', icon: FrostedGlyphs.file),
  RawNavigationDestination(label: 'Search', icon: FrostedGlyphs.search),
  RawNavigationDestination(label: 'Settings', icon: FrostedGlyphs.person),
];

Future<List<GlobalKey<NavigatorState>>> _pump(
  WidgetTester t, {
  double width = 390,
  TextDirection direction = TextDirection.ltr,
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
        child: FrostedHost(child: page!),
      ),
      home: FrostedAppShell(
        header: const FrostedWordmark('Shelf'),
        navigatorKeys: keys,
        destinations: _places,
        branches: [
          for (final place in _places)
            (context) => FrostedScaffold(
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
        const FrostedScaffold(body: Center(child: Text('Dune'))),
  ),
);

void main() {
  testWidgets('a phone: the tab bar along the foot, no sidebar', (t) async {
    await _pump(t);
    expect(find.byType(FrostedWordmark), findsNothing);
    for (final place in _places) {
      final r = t.getRect(find.text(place.label));
      expect(r.top, greaterThan(844 - 64 - 12), reason: place.label);
    }
    final root = t.getRect(find.text('Books root'));
    expect(root.bottom, lessThan(t.getRect(find.text('Books')).top));
    await t.tap(find.text('Search'));
    await t.pumpAndSettle();
    expect(find.text('Search root'), findsOneWidget);
  });

  for (final (width, bar) in [(1023.0, true), (1024.0, false)]) {
    testWidgets('at ${width.round()} the ${bar ? 'tab bar' : 'sidebar'}', (
      t,
    ) async {
      await _pump(t, width: width);
      expect(find.byType(FrostedWordmark), bar ? findsNothing : findsOneWidget);
    });
  }

  for (final direction in TextDirection.values) {
    testWidgets('a desktop, ${direction.name}: the sidebar at the start, '
        'its own width', (t) async {
      await _pump(t, width: 1440, direction: direction);
      final side = FrostedChromeMetrics.sideWidth;
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

  testWidgets('a desktop: a pushed page keeps the sidebar beside it', (
    t,
  ) async {
    final keys = await _pump(t, width: 1440);
    _push(keys[0]);
    await t.pumpAndSettle();
    expect(find.text('Dune'), findsOneWidget);
    expect(find.text('Search').hitTestable(), findsOneWidget);
    expect(
      t.getRect(find.text('Dune')).left,
      greaterThan(FrostedChromeMetrics.sideWidth),
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
    FrostedToast.show(t.element(find.text('Books root')), 'Saved');
    await t.pumpAndSettle();
    final toast = t.getRect(find.text('Saved'));
    expect(toast.bottom, lessThan(t.getRect(find.text('Books')).top));
    await t.pump(const Duration(seconds: 30));
    await t.pumpAndSettle();
  });

  testWidgets(
    "the sidebar's wordmark stands at its start edge in either direction",
    (t) async {
      Rect lockup() => t
          .getRect(find.byType(FrostedMark))
          .expandToInclude(t.getRect(find.text('Shelf')));
      await _pump(t, width: 1440);
      final ltr = lockup().left;
      await _pump(t, width: 1440, direction: TextDirection.rtl);
      final rtl = 1440 - lockup().right;
      expect(rtl, moreOrLessEquals(ltr, epsilon: 0.5));
    },
  );
}
