/// The toolbars family: the floating toolbar's container, colours and
/// expanding content, the with-FAB measure policy on both axes, the
/// toolbar FAB, the docked toolbar, the exit-always scroll behaviour, the
/// scroll expansion, accessibility (touch exploration, the expand /
/// collapse action) and the "no FAB menu beside a toolbar" check.
library;

import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

final ExpressiveThemeData _theme = ExpressiveThemeData.preset(
  'baseline',
  Brightness.light,
);

ExpressiveColorScheme get _c => _theme.colors;

Widget _app(Widget child, {bool hero = false}) => MaterialApp(
  home: ExpressiveHost(
    light: _theme,
    brightness: Brightness.light,
    child: Center(child: hero ? ExpressiveHeroMoment(child: child) : child),
  ),
);

Widget _act(String label) => ExpressiveIconButton(
  ExpressiveSymbols.edit,
  semanticLabel: label,
  onPressed: () {},
);

List<Widget> _acts(String prefix, int n) => <Widget>[
  for (var i = 0; i < n; i++)
    KeyedSubtree(key: ValueKey<String>('$prefix$i'), child: _act('$prefix $i')),
];

const Key _toolbar = ValueKey<String>('toolbar');
const Key _fab = ValueKey<String>('fab');

Widget _fabWidget({
  ExpressiveToolbarKind kind = ExpressiveToolbarKind.standard,
}) => KeyedSubtree(
  key: _fab,
  child: ExpressiveToolbarFab(
    icon: ExpressiveSymbols.add,
    semanticLabel: 'New',
    kind: kind,
    onPressed: () {},
  ),
);

Color _iconColour(WidgetTester tester, Finder icon) =>
    IconTheme.of(tester.element(icon)).color!;

void main() {
  group('ExpressiveFloatingToolbar', () {
    testWidgets('a 64dp pill: 8dp padding round 48dp targets, full corners', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(ExpressiveFloatingToolbar(key: _toolbar, children: _acts('a', 3))),
      );
      expect(tester.getSize(find.byKey(_toolbar)), const Size(3 * 48 + 16, 64));
      final surface = tester.widget<ExpressiveSurface>(
        find
            .descendant(
              of: find.byKey(_toolbar),
              matching: find.byType(ExpressiveSurface),
            )
            .first,
      );
      expect(surface.color, _c.surfaceContainer);
      expect(surface.contentColor, _c.onSurface);
      expect(surface.shadowElevation, ExpressiveElevationLevel.level0);
      final radii = (surface.shape as ExpressiveCornerBorder).radiiOn(
        Offset.zero & const Size(160, 64),
      );
      expect(radii.topLeft.x, 32);
      // A standard icon button takes the toolbar's content colour.
      expect(
        _iconColour(tester, find.byIcon(ExpressiveSymbols.edit).first),
        _c.onSurface,
      );
    });

    testWidgets('vibrant: primaryContainer with onPrimaryContainer', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          ExpressiveFloatingToolbar(
            kind: ExpressiveToolbarKind.vibrant,
            children: _acts('a', 2),
          ),
        ),
      );
      final surface = tester.widget<ExpressiveSurface>(
        find.byType(ExpressiveSurface).first,
      );
      expect(surface.color, _c.primaryContainer);
      expect(surface.contentColor, _c.onPrimaryContainer);
      expect(
        _iconColour(tester, find.byIcon(ExpressiveSymbols.edit).first),
        _c.onPrimaryContainer,
      );
    });

    testWidgets('leading and trailing content springs away and back', (
      tester,
    ) async {
      Widget build(bool expanded) => _app(
        ExpressiveFloatingToolbar(
          key: _toolbar,
          expanded: expanded,
          leading: _acts('lead', 2),
          trailing: _acts('trail', 1),
          children: _acts('core', 2),
        ),
      );
      await tester.pumpWidget(build(true));
      expect(tester.getSize(find.byKey(_toolbar)).width, 5 * 48 + 16);
      await tester.pumpWidget(build(false));
      await tester.pump(const Duration(milliseconds: 50));
      final mid = tester.getSize(find.byKey(_toolbar)).width;
      expect(mid, lessThan(5 * 48 + 16));
      expect(mid, greaterThan(2 * 48 + 16));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byKey(_toolbar)).width, 2 * 48 + 16);
      expect(find.byKey(const ValueKey<String>('lead0')), findsNothing);
      expect(find.byKey(const ValueKey<String>('trail0')), findsNothing);
      await tester.pumpWidget(build(true));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byKey(_toolbar)).width, 5 * 48 + 16);
    });

    testWidgets('vertical: a 64dp column', (tester) async {
      await tester.pumpWidget(
        _app(
          ExpressiveFloatingToolbar(
            key: _toolbar,
            axis: Axis.vertical,
            children: _acts('a', 3),
          ),
        ),
      );
      expect(tester.getSize(find.byKey(_toolbar)), const Size(64, 3 * 48 + 16));
    });

    testWidgets('beside a FAB: toolbar, 8dp gap, 56dp FAB, 80dp tall; '
        'collapsed, the FAB grows to 80dp and the toolbar shrinks away', (
      tester,
    ) async {
      Widget build(
        bool expanded, {
        ExpressiveToolbarFabPosition position =
            ExpressiveToolbarFabPosition.end,
      }) => _app(
        ExpressiveFloatingToolbar(
          key: _toolbar,
          expanded: expanded,
          fabPosition: position,
          floatingActionButton: _fabWidget(),
          children: _acts('a', 4),
        ),
      );
      const toolbarWidth = 4 * 48 + 16.0;
      const width = toolbarWidth + 8 + 56;
      await tester.pumpWidget(build(true));
      final origin = tester.getTopLeft(find.byKey(_toolbar));
      expect(tester.getSize(find.byKey(_toolbar)), const Size(width, 80));
      expect(tester.getSize(find.byKey(_fab)), const Size(56, 56));
      expect(
        tester.getTopLeft(find.byKey(_fab)) - origin,
        const Offset(width - 56, 12),
      );
      // The toolbar body: the first descendant with the toolbar's colour.
      final body = find.descendant(
        of: find.byKey(_toolbar),
        matching: find.byType(SingleChildScrollView),
      );
      expect(tester.getSize(body).width, toolbarWidth - 16);
      expect(tester.getTopLeft(body) - origin, const Offset(8, 16));

      await tester.pumpWidget(build(false));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byKey(_toolbar)), const Size(width, 80));
      expect(tester.getSize(find.byKey(_fab)), const Size(80, 80));
      expect(
        tester.getTopLeft(find.byKey(_fab)) - origin,
        const Offset(width - 80, 0),
      );

      // At the start: the FAB leads, the toolbar ends the layout.
      await tester.pumpWidget(
        build(true, position: ExpressiveToolbarFabPosition.start),
      );
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.byKey(_fab)) - origin, const Offset(0, 12));
      expect(
        tester.getTopLeft(body) - origin,
        const Offset(width - toolbarWidth + 8, 16),
      );
    });

    testWidgets('vertical beside a FAB: 80dp wide, the FAB below', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          ExpressiveFloatingToolbar(
            key: _toolbar,
            axis: Axis.vertical,
            floatingActionButton: _fabWidget(),
            children: _acts('a', 3),
          ),
        ),
      );
      const height = 3 * 48 + 16 + 8 + 56.0;
      final origin = tester.getTopLeft(find.byKey(_toolbar));
      expect(tester.getSize(find.byKey(_toolbar)), const Size(80, height));
      expect(
        tester.getTopLeft(find.byKey(_fab)) - origin,
        const Offset(12, height - 56),
      );
    });

    testWidgets('the toolbar FAB: primaryContainer (standard), '
        'tertiaryContainer (vibrant), level 2, 16dp corners', (tester) async {
      for (final (kind, colour) in [
        (ExpressiveToolbarKind.standard, _c.primaryContainer),
        (ExpressiveToolbarKind.vibrant, _c.tertiaryContainer),
      ]) {
        await tester.pumpWidget(
          _app(
            ExpressiveFloatingToolbar(
              kind: kind,
              floatingActionButton: _fabWidget(kind: kind),
              children: _acts('a', 2),
            ),
          ),
        );
        final pressable = tester.widget<ExpressivePressable>(
          find.descendant(
            of: find.byKey(_fab),
            matching: find.byType(ExpressivePressable),
          ),
        );
        expect(pressable.color, colour, reason: kind.name);
        expect(pressable.elevation.rest, ExpressiveElevationLevel.level2);
        expect(pressable.elevation.hovered, ExpressiveElevationLevel.level3);
        final radii = pressable.shapes.shape is ExpressiveCornerBorder
            ? (pressable.shapes.shape as ExpressiveCornerBorder).radiiOn(
                Offset.zero & const Size(56, 56),
              )
            : null;
        expect(radii?.topLeft.x, 16);
        expect(
          tester.getSize(
            find.descendant(of: find.byKey(_fab), matching: find.byType(Icon)),
          ),
          const Size(24, 24),
        );
      }
    });

    testWidgets('touch exploration keeps it expanded; the custom action '
        'collapses and expands it', (tester) async {
      final handle = tester.ensureSemantics();
      Widget build({required bool accessible}) => MediaQuery(
        data: MediaQueryData(accessibleNavigation: accessible),
        child: _app(
          ExpressiveFloatingToolbar(
            key: _toolbar,
            expanded: false,
            leading: _acts('lead', 1),
            children: _acts('core', 2),
          ),
        ),
      );
      await tester.pumpWidget(build(accessible: true));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey<String>('lead0')), findsOneWidget);

      final core = find.byKey(const ValueKey<String>('core0'));
      SemanticsNode actionsNode() {
        var node = tester.getSemantics(core);
        while (!node.getSemanticsData().hasAction(
          SemanticsAction.customAction,
        )) {
          node = node.parent!;
        }
        return node;
      }

      final data = actionsNode().getSemanticsData();
      final ids = data.customSemanticsActionIds!;
      expect(ids, hasLength(1));
      expect(
        CustomSemanticsAction.getAction(ids.single)!.label,
        'Collapse toolbar',
      );
      actionsNode().owner!.performAction(
        actionsNode().id,
        SemanticsAction.customAction,
        ids.single,
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey<String>('lead0')), findsNothing);
      final after = actionsNode().getSemanticsData().customSemanticsActionIds!;
      expect(
        CustomSemanticsAction.getAction(after.single)!.label,
        'Expand toolbar',
      );
      handle.dispose();
    });

    testWidgets('reports a FAB menu beside it', (tester) async {
      await tester.pumpWidget(
        _app(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ExpressiveFloatingToolbar(children: _acts('a', 2)),
              ExpressiveFabMenu(
                icon: ExpressiveSymbols.add,
                items: <ExpressiveFabMenuItem>[
                  for (final label in ['Photo', 'Note'])
                    ExpressiveFabMenuItem(
                      icon: ExpressiveSymbols.edit,
                      label: label,
                      onPressed: (_) {},
                    ),
                ],
              ),
            ],
          ),
          hero: true,
        ),
      );
      final error = tester.takeException();
      expect(error, isA<FlutterError>());
      expect('$error', contains('ExpressiveFloatingToolbar sits beside'));
    });
  });

  group('ExpressiveDockedToolbar', () {
    testWidgets('full width, 64dp over the bottom inset, surfaceContainer, '
        'square corners', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(400, 800),
            padding: EdgeInsets.only(bottom: 24),
          ),
          child: _app(
            Align(
              alignment: Alignment.bottomCenter,
              child: ExpressiveDockedToolbar(
                key: _toolbar,
                children: _acts('a', 4),
              ),
            ),
          ),
        ),
      );
      final size = tester.getSize(find.byKey(_toolbar));
      expect(size.height, 64 + 24);
      final surface = tester.widget<ExpressiveSurface>(
        find.byType(ExpressiveSurface).first,
      );
      expect(surface.color, _c.surfaceContainer);
      expect(
        (surface.shape as ExpressiveCornerBorder)
            .radiiOn(Offset.zero & size)
            .topLeft
            .x,
        0,
      );
      // Spread between the 16dp paddings.
      final left = tester.getTopLeft(find.byKey(_toolbar)).dx;
      expect(
        tester.getTopLeft(find.byKey(const ValueKey<String>('a0'))).dx - left,
        16,
      );
      expect(
        left +
            size.width -
            tester.getTopRight(find.byKey(const ValueKey<String>('a3'))).dx,
        16,
      );
    });

    testWidgets('fixed: centred, 32dp apart; vibrant colours', (tester) async {
      await tester.pumpWidget(
        _app(
          ExpressiveDockedToolbar(
            safeArea: false,
            kind: ExpressiveToolbarKind.vibrant,
            arrangement: ExpressiveDockedToolbarArrangement.fixed,
            children: _acts('a', 3),
          ),
        ),
      );
      final gap =
          tester.getTopLeft(find.byKey(const ValueKey<String>('a1'))).dx -
          tester.getTopRight(find.byKey(const ValueKey<String>('a0'))).dx;
      expect(gap, 32);
      final surface = tester.widget<ExpressiveSurface>(
        find.byType(ExpressiveSurface).first,
      );
      expect(surface.color, _c.primaryContainer);
      expect(surface.contentColor, _c.onPrimaryContainer);
    });
  });

  group('scroll', () {
    Widget scrolling({
      required Widget toolbar,
      required ExpressiveToolbarScrollBehavior behavior,
    }) => MaterialApp(
      home: ExpressiveHost(
        light: _theme,
        brightness: Brightness.light,
        child: Stack(
          children: <Widget>[
            NotificationListener<ScrollNotification>(
              onNotification: behavior.handleScrollNotification,
              child: ListView(
                key: const ValueKey<String>('list'),
                children: <Widget>[
                  for (var i = 0; i < 60; i++)
                    SizedBox(height: 48, child: Text('Row $i')),
                ],
              ),
            ),
            Align(alignment: Alignment.bottomCenter, child: toolbar),
          ],
        ),
      ),
    );

    testWidgets('exit always: the floating toolbar follows the scroll off '
        'and back, and snaps when the scroll stops part way', (tester) async {
      final behavior = ExpressiveToolbarScrollBehavior();
      addTearDown(behavior.dispose);
      await tester.pumpWidget(
        scrolling(
          behavior: behavior,
          toolbar: ExpressiveFloatingToolbar(
            key: _toolbar,
            scrollBehavior: behavior,
            children: _acts('a', 3),
          ),
        ),
      );
      final surface = find
          .descendant(
            of: find.byKey(_toolbar),
            matching: find.byType(ExpressiveSurface),
          )
          .first;
      final rest = tester.getTopLeft(surface).dy;
      final gesture = await tester.startGesture(const Offset(200, 300));
      await gesture.moveBy(const Offset(0, -40));
      await gesture.moveBy(const Offset(0, -10));
      await tester.pump();
      expect(behavior.offset, lessThan(0));
      final moved = tester.getTopLeft(surface).dy;
      expect(moved - rest, closeTo(-behavior.offset, 0.01));
      // The limit is the toolbar's distance to its parent's bottom: its
      // own height here.
      expect(behavior.offsetLimit, -64);
      await gesture.up();
      await tester.pumpAndSettle();
      // Past half way: it snapped fully off.
      expect(behavior.offset, -64);
      expect(behavior.collapsedFraction, 1);

      final back = await tester.startGesture(const Offset(200, 300));
      await back.moveBy(const Offset(0, 20));
      await back.moveBy(const Offset(0, 40));
      await back.up();
      await tester.pumpAndSettle();
      // Less than half off: it snapped back.
      expect(behavior.offset, 0);
      expect(tester.getTopLeft(surface).dy, rest);
    });

    testWidgets('exit always: the docked toolbar collapses its height', (
      tester,
    ) async {
      final behavior = ExpressiveToolbarScrollBehavior();
      addTearDown(behavior.dispose);
      await tester.pumpWidget(
        scrolling(
          behavior: behavior,
          toolbar: ExpressiveDockedToolbar(
            key: _toolbar,
            safeArea: false,
            scrollBehavior: behavior,
            children: _acts('a', 3),
          ),
        ),
      );
      expect(tester.getSize(find.byKey(_toolbar)).height, 64);
      await tester.drag(
        find.byKey(const ValueKey<String>('list')),
        const Offset(0, -20),
      );
      await tester.pump();
      expect(behavior.offsetLimit, -64);
      await tester.pumpAndSettle();
      // 20 of 64 off: snaps back.
      expect(behavior.offset, 0);
      await tester.drag(
        find.byKey(const ValueKey<String>('list')),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      expect(behavior.offset, -64);
      expect(tester.getSize(find.byKey(_toolbar)).height, 0);
    });

    testWidgets('scroll expansion: collapses after 40dp on, expands after '
        '40dp back', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          SizedBox(
            height: 400,
            child: ExpressiveToolbarScrollExpansion(
              child: ListView(
                controller: controller,
                children: <Widget>[
                  for (var i = 0; i < 60; i++)
                    SizedBox(height: 48, child: Text('Row $i')),
                ],
              ),
              builder: (context, expanded, list) => Column(
                children: <Widget>[
                  Expanded(child: list),
                  Text(expanded ? 'expanded' : 'collapsed'),
                ],
              ),
            ),
          ),
        ),
      );
      Future<void> scroll(double dy) async {
        // Content advancing is a positive position delta.
        controller.jumpTo(controller.offset - dy);
        await tester.pumpAndSettle();
      }

      await scroll(-30);
      expect(find.text('expanded'), findsOneWidget);
      await scroll(-30);
      expect(find.text('collapsed'), findsOneWidget);
      await scroll(20);
      expect(find.text('collapsed'), findsOneWidget);
      await scroll(40);
      expect(find.text('expanded'), findsOneWidget);
    });
  });
}
