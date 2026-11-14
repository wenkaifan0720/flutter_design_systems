/// The FAB family (components/fab.dart): the FAB's three sizes and six
/// colour styles, the extended FAB's expand/collapse, the FAB menu's toggle
/// morph, stagger and CONTRACT §3 asserts, the shell's action drawing each
/// kind of spec, the scroll-driven expansion, and the system back closing
/// an open menu.
library;

import 'dart:async';

import 'package:material_ui/material_ui.dart'
    show Material, MaterialApp, MaterialType;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/behavior.g.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/extended_fab_large_tokens.g.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/extended_fab_small_tokens.g.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/fab_baseline_tokens.g.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/fab_large_tokens.g.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/fab_medium_tokens.g.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/fab_menu_baseline_tokens.g.dart';

import 'support/pressable.dart';

final ExpressiveThemeData _theme = ExpressiveThemeData.preset(
  'baseline',
  Brightness.light,
);

Widget _app(Widget child, {bool hero = false}) => ExpressiveHost(
  light: _theme,
  brightness: Brightness.light,
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: const MediaQueryData(size: Size(800, 600)),
      child: Material(
        type: MaterialType.transparency,
        // The shell's action opens its menu's items in the overlay.
        child: Overlay.wrap(
          child: Align(
            alignment: Alignment.bottomRight,
            child: hero ? ExpressiveHeroMoment(child: child) : child,
          ),
        ),
      ),
    ),
  ),
);

ExpressiveSurface _surfaceOf(WidgetTester tester, Finder of) =>
    tester.widget<ExpressiveSurface>(
      find.descendant(of: of, matching: find.byType(ExpressiveSurface)).first,
    );

Size _surfaceSize(WidgetTester tester, Finder of) => tester.getSize(
  find.descendant(of: of, matching: find.byType(ExpressiveSurface)).first,
);

double _radius(WidgetTester tester, Finder of) {
  final shape = _surfaceOf(tester, of).shape as ExpressiveCornerBorder;
  final size = _surfaceSize(tester, of);
  return shape.radiiOn(Offset.zero & size).topLeft.x;
}

List<ExpressiveFabMenuItem> _items(int n, {List<String>? tapped}) => [
  for (var i = 0; i < n; i++)
    ExpressiveFabMenuItem(
      key: ValueKey<String>('item$i'),
      icon: ExpressiveSymbols.edit,
      label: 'Act $i',
      onPressed: (_) => tapped?.add('Act $i'),
    ),
];

void main() {
  group('ExpressiveFloatingActionButton', () {
    testWidgets('three sizes: container, corner and icon from the tokens', (
      tester,
    ) async {
      const cases = <(ExpressiveFabSize, double, double, double)>[
        (
          ExpressiveFabSize.standard,
          FabBaselineTokens.containerHeight,
          16,
          FabBaselineTokens.iconSize,
        ),
        (ExpressiveFabSize.medium, FabMediumTokens.containerHeight, 20, 28),
        (ExpressiveFabSize.large, FabLargeTokens.containerHeight, 28, 36),
      ];
      for (final (size, side, corner, icon) in cases) {
        await tester.pumpWidget(
          _app(
            ExpressiveFloatingActionButton(
              key: const ValueKey<String>('fab'),
              icon: ExpressiveSymbols.add,
              size: size,
              semanticLabel: 'New',
              onPressed: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        final fab = find.byKey(const ValueKey<String>('fab'));
        expect(_surfaceSize(tester, fab), Size(side, side), reason: '$size');
        expect(_radius(tester, fab), corner, reason: '$size');
        expect(tester.getSize(find.byType(Icon)).width, icon, reason: '$size');
      }
      expect(FabMediumTokens.containerHeight, 80);
      expect(FabLargeTokens.containerHeight, 96);
    });

    testWidgets('six colour styles: container and content roles', (
      tester,
    ) async {
      final c = _theme.colors;
      final expected = <ExpressiveFabColor, (Color, Color)>{
        ExpressiveFabColor.primaryContainer: (
          c.primaryContainer,
          c.onPrimaryContainer,
        ),
        ExpressiveFabColor.secondaryContainer: (
          c.secondaryContainer,
          c.onSecondaryContainer,
        ),
        ExpressiveFabColor.tertiaryContainer: (
          c.tertiaryContainer,
          c.onTertiaryContainer,
        ),
        ExpressiveFabColor.primary: (c.primary, c.onPrimary),
        ExpressiveFabColor.secondary: (c.secondary, c.onSecondary),
        ExpressiveFabColor.tertiary: (c.tertiary, c.onTertiary),
      };
      for (final MapEntry(key: style, value: (container, content))
          in expected.entries) {
        await tester.pumpWidget(
          _app(
            ExpressiveFloatingActionButton(
              icon: ExpressiveSymbols.add,
              color: style,
              onPressed: () {},
            ),
          ),
        );
        // Each style replaces the last in place: its colours spring there.
        await tester.pumpAndSettle();
        final surface = _surfaceOf(
          tester,
          find.byType(ExpressiveFloatingActionButton),
        );
        expect(surface.color, container, reason: '$style');
        expect(surface.contentColor, content, reason: '$style');
        expect(
          surface.shadowElevation,
          ExpressiveElevationLevel.level3,
          reason: '$style',
        );
      }
    });

    testWidgets('lowered sits at level 1; taps and announces its act', (
      tester,
    ) async {
      var taps = 0;
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          ExpressiveFloatingActionButton(
            icon: ExpressiveSymbols.add,
            lowered: true,
            semanticLabel: 'New list',
            onPressed: () => taps++,
          ),
        ),
      );
      expect(
        _surfaceOf(
          tester,
          find.byType(ExpressiveFloatingActionButton),
        ).shadowElevation,
        ExpressiveElevationLevel.level1,
      );
      await tester.tap(find.byType(ExpressiveFloatingActionButton));
      expect(taps, 1);
      expect(find.bySemanticsLabel('New list'), findsOneWidget);
      semantics.dispose();
    });
  });

  group('ExpressiveFloatingActionButton', () {
    testWidgets('expanded: height, paddings and label by size', (tester) async {
      await tester.pumpWidget(
        _app(
          ExpressiveFloatingActionButton.extended(
            icon: ExpressiveSymbols.edit,
            label: 'Compose',
            onPressed: () {},
          ),
        ),
      );
      final fab = find.byType(ExpressiveFloatingActionButton);
      final size = _surfaceSize(tester, fab);
      expect(size.height, ExtendedFabSmallTokens.containerHeight);
      final text = tester.getSize(find.text('Compose'));
      expect(
        size.width,
        closeTo(
          ExtendedFabSmallTokens.leadingSpace +
              ExtendedFabSmallTokens.iconSize +
              ExtendedFabSmallTokens.iconLabelSpace +
              text.width +
              ExtendedFabSmallTokens.trailingSpace,
          0.01,
        ),
      );
      expect(_radius(tester, fab), 16);
      expect(
        DefaultTextStyle.of(tester.element(find.text('Compose')))
            .style
            .fontSize,
        _theme.type.titleMedium.fontSize,
      );

      await tester.pumpWidget(
        _app(
          ExpressiveFloatingActionButton.extended(
            icon: ExpressiveSymbols.edit,
            label: 'Compose',
            size: ExpressiveFabSize.large,
            onPressed: () {},
          ),
        ),
      );
      expect(
        _surfaceSize(tester, fab).height,
        ExtendedFabLargeTokens.containerHeight,
      );
      expect(
        DefaultTextStyle.of(tester.element(find.text('Compose')))
            .style
            .fontSize,
        _theme.type.headlineSmall.fontSize,
      );
      expect(
        tester.getSize(find.byType(Icon)).width,
        ExtendedFabLargeTokens.iconSize,
      );
    });

    testWidgets('collapses to the square on a spring and back', (tester) async {
      Widget fab(bool expanded) => _app(
        ExpressiveFloatingActionButton.extended(
          icon: ExpressiveSymbols.edit,
          label: 'Compose',
          expanded: expanded,
          onPressed: () {},
        ),
      );
      final finder = find.byType(ExpressiveFloatingActionButton);
      await tester.pumpWidget(fab(true));
      final wide = _surfaceSize(tester, finder).width;

      await tester.pumpWidget(fab(false));
      await tester.pump(const Duration(milliseconds: 50));
      final mid = _surfaceSize(tester, finder).width;
      expect(mid, lessThan(wide));
      expect(mid, greaterThan(ExtendedFabSmallTokens.containerHeight));
      await tester.pumpAndSettle();
      expect(
        _surfaceSize(tester, finder),
        const Size.square(ExtendedFabSmallTokens.containerHeight),
      );
      expect(
        find.text('Compose'),
        findsNothing,
        reason: 'dropped when settled',
      );
      expect(find.bySemanticsLabel('Compose'), findsOneWidget);

      await tester.pumpWidget(fab(true));
      await tester.pumpAndSettle();
      expect(_surfaceSize(tester, finder).width, closeTo(wide, 0.01));
    });

    testWidgets('ExpressiveFabScrollExpansion collapses on scroll down', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SizedBox(
            height: 400,
            width: 300,
            child: ExpressiveFabScrollExpansion(
              child: ListView(
                children: [
                  for (var i = 0; i < 40; i++)
                    SizedBox(height: 48, child: Text('Row $i')),
                ],
              ),
              builder: (context, expanded, child) => Stack(
                children: [
                  child,
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: ExpressiveFloatingActionButton.extended(
                      icon: ExpressiveSymbols.edit,
                      label: 'Compose',
                      expanded: expanded,
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      ExpressiveFloatingActionButton fab() =>
          tester.widget<ExpressiveFloatingActionButton>(
            find.byType(ExpressiveFloatingActionButton),
          );
      expect(fab().expanded, isTrue);
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(fab().expanded, isFalse);
      await tester.drag(find.byType(ListView), const Offset(0, 100));
      await tester.pumpAndSettle();
      expect(fab().expanded, isTrue);
    });
  });

  group('ExpressiveFabMenu', () {
    testWidgets('asserts an ExpressiveHeroMoment above it', (tester) async {
      await tester.pumpWidget(
        _app(ExpressiveFabMenu(icon: ExpressiveSymbols.add, items: _items(3))),
      );
      expect(tester.takeException(), isA<FlutterError>());
    });

    testWidgets('asserts 2–5 items', (tester) async {
      for (final n in <int>[1, 6]) {
        await tester.pumpWidget(
          _app(
            ExpressiveFabMenu(icon: ExpressiveSymbols.add, items: _items(n)),
            hero: true,
          ),
        );
        final error = tester.takeException();
        expect(error, isA<FlutterError>(), reason: '$n items');
        expect('$error', contains('2–5 items'));
      }
    });

    testWidgets('opens: the toggle morphs, the items stagger in from the '
        'bottom, an item runs its act and closes the menu', (tester) async {
      final tapped = <String>[];
      final changes = <bool>[];
      await tester.pumpWidget(
        _app(
          ExpressiveFabMenu(
            icon: ExpressiveSymbols.add,
            semanticLabel: 'Create',
            size: ExpressiveFabSize.medium,
            items: _items(3, tapped: tapped),
            onExpandedChanged: changes.add,
            buttonKey: const ValueKey<String>('toggle'),
          ),
          hero: true,
        ),
      );
      final toggle = find.byKey(const ValueKey<String>('toggle'));
      // Closed, the items stay laid out (zero wide, as Compose keeps them) in
      // a column clipped to zero height: none shows or takes a tap.
      expect(find.text('Act 0').hitTestable(), findsNothing);
      expect(_surfaceSize(tester, toggle), const Size.square(80));
      expect(_radius(tester, toggle), 20);
      expect(_surfaceOf(tester, toggle).color, _theme.colors.primaryContainer);

      await tester.tap(toggle);
      expect(changes, <bool>[true]);
      // Frame by frame, the bottom item shows before the top one.
      var bottomFirst = false;
      for (var f = 0; f < 60; f++) {
        await tester.pump(const Duration(milliseconds: 16));
        final top = find.byKey(const ValueKey<String>('item0'));
        final bottom = find.byKey(const ValueKey<String>('item2'));
        if (bottom.evaluate().isNotEmpty &&
            tester
                    .widget<Opacity>(
                      find.ancestor(of: bottom, matching: find.byType(Opacity)),
                    )
                    .opacity >
                0 &&
            tester
                    .widget<Opacity>(
                      find.ancestor(of: top, matching: find.byType(Opacity)),
                    )
                    .opacity ==
                0) {
          bottomFirst = true;
        }
      }
      expect(bottomFirst, isTrue);
      await tester.pumpAndSettle();
      expect(
        _surfaceSize(tester, toggle),
        const Size.square(FabMenuBaselineTokens.closeButtonContainerHeight),
      );
      expect(_radius(tester, toggle), 28);
      expect(_surfaceOf(tester, toggle).color, _theme.colors.primary);
      final item = find.byKey(const ValueKey<String>('item1'));
      expect(
        _surfaceSize(tester, item).height,
        FabMenuBaselineTokens.listItemContainerHeight,
      );
      expect(_surfaceOf(tester, item).color, _theme.colors.primaryContainer);
      // The open toggle sits at the top end of the closed toggle's box.
      final box = tester.getRect(
        find.ancestor(of: toggle, matching: find.byType(ConstrainedBox)).first,
      );
      expect(box.size, const Size.square(80));
      expect(tester.getRect(toggle).topRight, box.topRight);

      await tester.tap(pressableOf(find.text('Act 1')));
      expect(tapped, <String>['Act 1']);
      expect(changes, <bool>[true, false]);
      await tester.pumpAndSettle();
      expect(find.text('Act 1').hitTestable(), findsNothing);
      expect(_surfaceSize(tester, toggle), const Size.square(80));
    });

    testWidgets('padding: 16dp either side and below, unless unpadded', (
      tester,
    ) async {
      Future<Rect> toggleRect({required bool padded}) async {
        await tester.pumpWidget(
          _app(
            ExpressiveFabMenu(
              icon: ExpressiveSymbols.add,
              items: _items(2),
              padded: padded,
              buttonKey: const ValueKey<String>('toggle'),
            ),
            hero: true,
          ),
        );
        return tester.getRect(find.byKey(const ValueKey<String>('toggle')));
      }

      final padded = await toggleRect(padded: true);
      expect(
        padded.right,
        800 - FloatingActionButtonMenuBehavior.paddingHorizontal,
      );
      expect(
        padded.bottom,
        600 - FloatingActionButtonMenuBehavior.buttonPaddingBottom,
      );
      final bare = await toggleRect(padded: false);
      expect(bare.bottomRight, const Offset(800, 600));
    });

    testWidgets('countOn and debugCheckNoMenuBeside', (tester) async {
      await tester.pumpWidget(
        _app(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Builder(
                builder: (context) {
                  assert(
                    ExpressiveFabMenu.debugCheckNoMenuBeside(
                      context,
                      'A toolbar',
                    ),
                  );
                  return const SizedBox.shrink();
                },
              ),
              ExpressiveFabMenu(icon: ExpressiveSymbols.add, items: _items(2)),
            ],
          ),
          hero: true,
        ),
      );
      expect(ExpressiveFabMenu.countOn(null), 1);
      final error = tester.takeException();
      expect('$error', contains('A toolbar sits beside an ExpressiveFabMenu'));
      await tester.pumpWidget(_app(const SizedBox.shrink()));
      expect(ExpressiveFabMenu.countOn(null), 0);
    });

    group('the system back', () {
      /// A page pushed over the app's first one, holding [menu] and asking
      /// before it is left: [asked] counts the backs its PopScope saw.
      Future<void> pushPage(
        WidgetTester tester,
        Widget menu,
        List<bool> asked,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, app) => ExpressiveHost(
              light: _theme,
              brightness: Brightness.light,
              child: app!,
            ),
            home: const SizedBox.expand(),
          ),
        );
        final navigator = tester.state<NavigatorState>(find.byType(Navigator));
        unawaited(
          navigator.push(
            ExpressivePage<void>(
              child: PopScope<Object?>(
                canPop: false,
                onPopInvokedWithResult: (didPop, _) => asked.add(didPop),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: ExpressiveHeroMoment(child: menu),
                ),
              ),
            ).createRoute(navigator.context),
          ),
        );
        await tester.pumpAndSettle();
      }

      const toggle = ValueKey<String>('toggle');

      for (final overlay in <bool>[false, true]) {
        testWidgets('closes an open menu before it reaches the page '
            '(${overlay ? 'items in the overlay' : 'items in its box'})', (
          tester,
        ) async {
          final asked = <bool>[];
          final changes = <bool>[];
          await pushPage(
            tester,
            ExpressiveFabMenu(
              icon: ExpressiveSymbols.add,
              items: _items(3),
              overlayItems: overlay,
              onExpandedChanged: changes.add,
              buttonKey: toggle,
            ),
            asked,
          );
          await tester.tap(find.byKey(toggle));
          await tester.pumpAndSettle();
          expect(find.text('Act 1').hitTestable(), findsOneWidget);

          expect(await tester.binding.handlePopRoute(), isTrue);
          await tester.pumpAndSettle();
          expect(changes, <bool>[true, false]);
          expect(find.text('Act 1').hitTestable(), findsNothing);
          // The toggle is the closed FAB again.
          expect(_radius(tester, find.byKey(toggle)), 16);
          expect(asked, isEmpty);

          // Closed, the back is the page's.
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(asked, <bool>[false]);
        });
      }

      testWidgets('a controlled menu is asked to close, and closes when the '
          'caller says so', (tester) async {
        final asked = <bool>[];
        var expanded = true;
        await pushPage(
          tester,
          StatefulBuilder(
            builder: (context, update) => ExpressiveFabMenu(
              icon: ExpressiveSymbols.add,
              items: _items(2),
              expanded: expanded,
              onExpandedChanged: (value) => update(() => expanded = value),
            ),
          ),
          asked,
        );
        expect(find.text('Act 1').hitTestable(), findsOneWidget);
        expect(await tester.binding.handlePopRoute(), isTrue);
        await tester.pumpAndSettle();
        expect(expanded, isFalse);
        expect(find.text('Act 1').hitTestable(), findsNothing);
        expect(asked, isEmpty);
      });
    });
  });

  group('ExpressiveShellAction', () {
    testWidgets('is the kit spec, and draws a plain spec as the FAB', (
      tester,
    ) async {
      const spec = ExpressiveShellAction(
        icon: ExpressiveSymbols.add,
        onPressed: _noop,
        accent: true,
      );
      expect(spec, isA<ShellAction>());
      BuildContext? ran;
      await tester.pumpWidget(
        _app(
          ExpressiveShellAction(
            action: ShellAction(
              icon: ExpressiveSymbols.add,
              label: 'New habit',
              key: const ValueKey<String>('step'),
              onPressed: (context) => ran = context,
            ),
          ),
        ),
      );
      final fab = find.byType(ExpressiveFloatingActionButton);
      expect(fab, findsOneWidget);
      expect(_surfaceSize(tester, fab), const Size.square(56));
      expect(
        _surfaceOf(tester, fab).color,
        _theme.colors.primaryContainer,
        reason: 'the quiet default',
      );
      await tester.tap(find.byKey(const ValueKey<String>('step')));
      expect(ran, isNotNull);

      await tester.pumpWidget(_app(const ExpressiveShellAction(action: spec)));
      expect(
        _surfaceOf(tester, find.byType(ExpressiveFloatingActionButton)).color,
        _theme.colors.primary,
        reason: 'accent',
      );
    });

    testWidgets('a label draws the extended FAB; a menu the FAB menu', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const ExpressiveShellAction(
            action: ExpressiveShellAction(
              icon: ExpressiveSymbols.edit,
              label: 'Check in',
              onPressed: _noop,
            ),
          ),
        ),
      );
      expect(find.byType(ExpressiveFloatingActionButton), findsOneWidget);
      expect(find.text('Check in'), findsOneWidget);

      var opened = 0;
      await tester.pumpWidget(
        _app(
          ExpressiveShellAction(
            action: ExpressiveShellAction(
              icon: ExpressiveSymbols.add,
              key: const ValueKey<String>('create'),
              onPressed: (_) => opened++,
              menu: _items(3),
            ),
          ),
        ),
      );
      expect(find.byType(ExpressiveHeroMoment), findsOneWidget);
      expect(find.byType(ExpressiveFabMenu), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey<String>('create')));
      await tester.pumpAndSettle();
      expect(opened, 1);
      expect(find.text('Act 2'), findsOneWidget);
      // The shell pads it; the menu keeps none of its own.
      expect(
        tester.getBottomRight(find.byKey(const ValueKey<String>('create'))),
        const Offset(800, 600),
      );
    });

    test('a menu never opens from an extended FAB', () {
      expect(
        () => ExpressiveShellAction(
          icon: ExpressiveSymbols.add,
          label: 'Create',
          menu: _items(2),
        ),
        throwsAssertionError,
      );
      expect(
        () =>
            ExpressiveShellAction(icon: ExpressiveSymbols.add, menu: _items(1)),
        throwsAssertionError,
      );
    });
  });
}

void _noop(BuildContext context) {}
