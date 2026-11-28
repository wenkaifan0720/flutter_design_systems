// A bottom sheet raised over the app shell stands on its tab bar: the slab's foot meets the bar's top at 390, by day,
// left to right and right to left, with and without a home-indicator inset, and at a tablet's width where the bar
// still shows. The bar stays put and keeps the inset, its places stay whole under the veil, a press on it closes the
// sheet and keeps the place, and a drag down closes it too. With no bar the sheet stands on the screen's foot as
// before; from a desktop's width it floats in the middle of the window as before.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

const _places = [
  RawNavigationDestination(label: 'Books', icon: NeumorphicGlyphs.file),
  RawNavigationDestination(label: 'Search', icon: NeumorphicGlyphs.search),
  RawNavigationDestination(label: 'Settings', icon: NeumorphicGlyphs.settings),
];

final _sheet = find.byType(NeumorphicBottomSheet);

ModalRoute<Object?>? _route(WidgetTester tester) =>
    ModalRoute.of(tester.element(find.text('By title')));

Future<void> _pump(
  WidgetTester tester, {
  double width = 390,
  double inset = 0,
  bool shell = true,
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  tester.view.padding = FakeViewPadding(bottom: inset);
  addTearDown(tester.view.reset);
  Widget page(String title) => NeumorphicScaffold(
    body: Center(
      child: Builder(
        builder: (context) => NeumorphicButton(
          'Sort',
          onPressed: () => showNeumorphicBottomSheet<void>(
            context,
            builder: (context) => const NeumorphicBottomSheet(
              title: 'Sort books',
              child: Text('By title'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, app) => Directionality(
        textDirection: direction,
        child: NeumorphicHost(brightness: Brightness.light, child: app!),
      ),
      home: shell
          ? NeumorphicAppShell(
              destinations: _places,
              branches: [
                for (final place in _places) (context) => page(place.label),
              ],
            )
          : page('Books'),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('Sort').first);
  await tester.pumpAndSettle();
}

// The bar: the nearest box as wide as the screen around a place's words.
Rect _bar(WidgetTester tester) {
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
  throw StateError('no bar');
}

void main() {
  setUpAll(loadNeumorphicFonts);

  for (final direction in TextDirection.values) {
    for (final inset in [0.0, 34.0]) {
      testWidgets(
        'at 390 the sheet stands on the bar (${direction.name}, inset ${inset.toInt()})',
        (tester) async {
          await _pump(tester, inset: inset, direction: direction);
          final bar = _bar(tester);
          expect(bar.bottom, 844, reason: 'the bar keeps the inset');
          await _open(tester);
          expect(_route(tester), isA<RawBottomSheetRoute<void>>());
          expect(_bar(tester), bar, reason: 'the bar stays put');
          final slab = tester.getRect(_sheet);
          expect(slab.bottom, moreOrLessEquals(bar.top, epsilon: .01));
          expect(slab.left, 0);
          expect(slab.right, 390);
          for (final place in _places) {
            final words = tester.getRect(find.text(place.label).last);
            expect(
              words.top,
              greaterThanOrEqualTo(slab.bottom),
              reason: place.label,
            );
          }
        },
      );
    }
  }

  testWidgets(
    'at a tablet\'s width, where the bar shows, the sheet stands on it',
    (tester) async {
      await _pump(tester, width: 900);
      final bar = _bar(tester);
      await _open(tester);
      final slab = tester.getRect(_sheet);
      expect(slab.bottom, moreOrLessEquals(bar.top, epsilon: .01));
      expect(slab.width, 560);
      expect(slab.center.dx, 450);
    },
  );

  testWidgets('a press on the bar closes the sheet and keeps the place', (
    tester,
  ) async {
    await _pump(tester, inset: 34);
    await _open(tester);
    await tester.tapAt(tester.getCenter(find.text('Settings').last));
    await tester.pumpAndSettle();
    expect(_sheet, findsNothing);
    expect(find.text('Sort'), findsOneWidget);
    expect(tester.getRect(find.text('Sort')).center.dx, 195);
  });

  testWidgets('a drag down closes the sheet', (tester) async {
    await _pump(tester);
    await _open(tester);
    await tester.drag(find.text('Sort books'), const Offset(0, 300));
    await tester.pumpAndSettle();
    expect(_sheet, findsNothing);
  });

  testWidgets('a screen reader hears the sheet named by its title', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester);
    await _open(tester);
    final title = tester.getSemantics(find.text('Sort books'));
    expect(title.flagsCollection.isHeader, isTrue);
    expect(title.flagsCollection.namesRoute, isTrue);
    // The innermost route scope round the title is named by it.
    SemanticsNode? scope = title.parent;
    while (scope != null && !scope.flagsCollection.scopesRoute) {
      scope = scope.parent;
    }
    String? name;
    void first(SemanticsNode node) {
      if (name != null) return;
      if (node.flagsCollection.namesRoute && node.label.isNotEmpty) {
        name = node.label;
        return;
      }
      node.visitChildren((child) {
        first(child);
        return name == null;
      });
    }

    first(scope!);
    expect(name, 'Sort books');
    semantics.dispose();
  });

  testWidgets('with no bar the sheet stands on the screen\'s foot', (
    tester,
  ) async {
    await _pump(tester, inset: 34, shell: false);
    await _open(tester);
    expect(tester.getRect(_sheet).bottom, 844);
    expect(
      tester.getRect(find.text('By title')).bottom,
      lessThanOrEqualTo(844 - 34),
    );
  });

  testWidgets('from a desktop\'s width the sheet floats in the middle', (
    tester,
  ) async {
    await _pump(tester, width: 1440, shell: false);
    await _open(tester);
    expect(_route(tester), isNot(isA<RawBottomSheetRoute<void>>()));
    expect(tester.getRect(_sheet).center.dy, moreOrLessEquals(422, epsilon: 1));
  });
}
