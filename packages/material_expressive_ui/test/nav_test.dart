/// Navigation: the flexible navigation bar, the rail and the tabs, held to
/// the geometry, colours and motion Compose material3 1.5.0-alpha29 gives
/// them (`ShortNavigationBar.kt`, `NavigationItem.kt`,
/// `WideNavigationRail.kt`, `TabRow.kt`, `Tab.kt`) — each number below
/// recomputed by hand from the tokens, not read back from the code.
library;

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart'
    show RenderParagraph, RenderRepaintBoundary;
import 'package:flutter/services.dart' show ByteData;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

final ExpressiveThemeData _theme = ExpressiveThemeData.preset(
  'baseline',
  Brightness.light,
);

const Size _phone = Size(412, 892);

Widget _app(
  Widget child, {
  double textScale = 1,
  EdgeInsets padding = EdgeInsets.zero,
  double dpr = 1,
  ExpressiveThemeData? theme,
}) => ExpressiveHost(
  light: theme ?? _theme,
  brightness: Brightness.light,
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: MediaQueryData(
        size: _phone,
        padding: padding,
        devicePixelRatio: dpr,
        textScaler: TextScaler.linear(textScale),
      ),
      child: Shortcuts(
        shortcuts: WidgetsApp.defaultShortcuts,
        child: Align(alignment: Alignment.topLeft, child: child),
      ),
    ),
  ),
);

const List<ExpressiveNavItem> _items = <ExpressiveNavItem>[
  ExpressiveNavItem(ExpressiveSymbols.home, 'Home', key: ValueKey('home')),
  ExpressiveNavItem(
    ExpressiveSymbols.explore,
    'Explore',
    key: ValueKey('explore'),
  ),
  ExpressiveNavItem(ExpressiveSymbols.person, 'You', key: ValueKey('you')),
];

/// A bar [width] wide keeping its own selection.
class _Bar extends StatefulWidget {
  const _Bar({
    this.items = _items,
    this.width = 408,
    this.position = ExpressiveNavItemPosition.top,
  });

  final List<ExpressiveNavItem> items;
  final double width;
  final ExpressiveNavItemPosition position;

  @override
  State<_Bar> createState() => _BarState();
}

class _BarState extends State<_Bar> {
  int selected = 0;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: widget.width,
    child: ExpressiveNavigationBar(
      destinations: widget.items,
      selectedIndex: selected,
      onDestinationSelected: (index) => setState(() => selected = index),
      itemPosition: widget.position,
    ),
  );
}

Rect _iconRect(WidgetTester tester, IconData icon) =>
    tester.getRect(find.byIcon(icon));

/// The item's active indicator: the box painted in `secondaryContainer`
/// (at any alpha).
Finder _indicatorFinder(Key item) => find
    .descendant(
      of: find.byKey(item),
      matching: find.byWidgetPredicate((w) {
        if (w is! DecoratedBox) return false;
        final decoration = w.decoration;
        if (decoration is! ShapeDecoration) return false;
        final color = decoration.color;
        return color != null &&
            color.withValues(alpha: 1) == _theme.colors.secondaryContainer;
      }),
    )
    .first;

Rect _indicatorOf(WidgetTester tester, Key item) =>
    tester.getRect(_indicatorFinder(item));

Color _indicatorColor(WidgetTester tester, Key item) =>
    (tester.widget<DecoratedBox>(_indicatorFinder(item)).decoration
            as ShapeDecoration)
        .color!;

Color _textColor(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style!.color!;

void main() {
  testWidgets('a narrow navigation bar keeps reachable destination targets', (
    tester,
  ) async {
    int? picked;
    await tester.pumpWidget(
      _app(
        SizedBox(
          width: 120,
          child: ExpressiveNavigationBar(
            destinations: _items,
            selectedIndex: 0,
            onDestinationSelected: (index) => picked = index,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (final key in ['home', 'explore', 'you']) {
      expect(
        tester.getSize(find.byKey(ValueKey(key))).width,
        greaterThanOrEqualTo(48),
      );
    }
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(-300, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('you')));
    expect(picked, 2);
  });

  testWidgets('item style falls through by state and updates when disabled', (
    tester,
  ) async {
    const selectedInk = Color(0xff123456);
    const pressedInk = Color(0xff654321);
    const disabledInk = Color(0xff999999);
    const rim = Color(0xff456789);
    var hits = 0;
    var enabled = true;
    late StateSetter rebuild;
    final theme = _theme.copyWith(
      navigationItemTheme: ExpressiveComponentThemeData(
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.disabled) ? disabledInk : selectedInk,
        ),
        outline: const WidgetStatePropertyAll(rim),
      ),
    );
    await tester.pumpWidget(
      ExpressiveHost(
        light: theme,
        brightness: Brightness.light,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(),
            child: StatefulBuilder(
              builder: (context, setState) {
                rebuild = setState;
                return Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: 240,
                    child: ExpressiveNavigationBar(
                      destinations: [
                        ExpressiveNavItem(
                          ExpressiveSymbols.home,
                          'Home',
                          key: const ValueKey('styled'),
                          enabled: enabled,
                          style: ExpressiveComponentThemeData(
                            foregroundColor: WidgetStateProperty.resolveWith(
                              (states) => states.contains(WidgetState.pressed)
                                  ? pressedInk
                                  : null,
                            ),
                          ),
                        ),
                      ],
                      selectedIndex: 0,
                      onDestinationSelected: (_) => hits++,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(_textColor(tester, 'Home'), selectedInk);
    final decoration = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .map((w) => w.decoration)
        .whereType<ShapeDecoration>()
        .firstWhere(
          (d) =>
              d.shape is OutlinedBorder &&
              (d.shape as OutlinedBorder).side.color == rim,
        );
    expect((decoration.shape as OutlinedBorder).side.style, BorderStyle.solid);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('styled'))),
    );
    await tester.pumpAndSettle();
    expect(_textColor(tester, 'Home'), pressedInk);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(_textColor(tester, 'Home'), selectedInk);
    expect(hits, 1);
    rebuild(() => enabled = false);
    await tester.pumpAndSettle();
    expect(_textColor(tester, 'Home'), disabledInk);
    await tester.tap(find.byKey(const ValueKey('styled')));
    await tester.pumpAndSettle();
    expect(hits, 1);
    expect(tester.takeException(), isNull);
  });

  group('the flexible navigation bar', () {
    testWidgets('is 64dp of surfaceContainer, items sharing the width', (
      tester,
    ) async {
      await tester.pumpWidget(_app(const _Bar()));
      final bar = tester.getRect(find.byType(ExpressiveNavigationBar));
      expect(bar.height, 64);
      final fill = tester.widget<ExpressiveSurface>(
        find
            .descendant(
              of: find.byType(ExpressiveNavigationBar),
              matching: find.byType(ExpressiveSurface),
            )
            .first,
      );
      expect(fill.color, _theme.colors.surfaceContainer);
      // EqualWeight: 408 / 3 = 136 each.
      expect(tester.getRect(find.byKey(const ValueKey('home'))).width, 136);
      expect(tester.getRect(find.byKey(const ValueKey('explore'))).left, 136);
    });

    testWidgets('divides whole device pixels, as Compose does', (tester) async {
      // 400dp at 2.625 = 1050px; / 4 = 262px (262.5 floored) = 99.81dp.
      await tester.pumpWidget(
        _app(
          const _Bar(width: 400, items: <ExpressiveNavItem>[..._items, _extra]),
          dpr: 2.625,
        ),
      );
      expect(
        tester.getRect(find.byKey(const ValueKey('you'))).left,
        closeTo(262 * 2 / 2.625, 1e-9),
      );
    });

    testWidgets('a vertical item: pill 56×32 6dp down, icon 24 inside it, '
        'label 4dp under it', (tester) async {
      await tester.pumpWidget(_app(const _Bar()));
      const home = ValueKey('home');
      final item = tester.getRect(find.byKey(home));
      final indicator = _indicatorOf(tester, home);
      expect(indicator.size, const Size(56, 32));
      expect(indicator.top - item.top, 6);
      expect(indicator.center.dx, item.center.dx);
      final icon = _iconRect(tester, ExpressiveSymbols.home);
      expect(icon.size, const Size(24, 24));
      expect(icon.top - item.top, 10);
      expect(icon.center.dx, item.center.dx);
      final label = tester.getRect(find.text('Home'));
      // 6 + 4 + 24 + 4 + 4.
      expect(label.top - item.top, 42);
      expect(label.center.dx, closeTo(item.center.dx, 0.5));
    });

    testWidgets('a horizontal item: a 40dp pill around icon and label', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(const _Bar(position: ExpressiveNavItemPosition.start)),
      );
      const home = ValueKey('home');
      final item = tester.getRect(find.byKey(home));
      final indicator = _indicatorOf(tester, home);
      final icon = _iconRect(tester, ExpressiveSymbols.home);
      final label = tester.getRect(find.text('Home'));
      expect(indicator.height, 40);
      // 16 + icon 24 + 4 + label + 16.
      expect(indicator.width, 16 + 24 + 4 + label.width + 16);
      expect(indicator.center, item.center);
      expect(icon.left - indicator.left, 16);
      expect(label.left - icon.right, 4);
      expect(_textColor(tester, 'Home'), _theme.colors.onSecondaryContainer);
    });

    testWidgets('the selected item wears the pill, the filled icon and the '
        'secondary label; the others onSurfaceVariant', (tester) async {
      await tester.pumpWidget(_app(const _Bar()));
      expect(
        _indicatorColor(tester, const ValueKey('home')),
        _theme.colors.secondaryContainer,
      );
      expect(_textColor(tester, 'Home'), _theme.colors.secondary);
      expect(_textColor(tester, 'Explore'), _theme.colors.onSurfaceVariant);
      final icons = tester.widgetList<Icon>(find.byType(Icon)).toList();
      expect(icons[0].fill, ExpressiveSymbolsFont.filled);
      expect(icons[0].color, _theme.colors.onSecondaryContainer);
      expect(icons[1].fill, ExpressiveSymbolsFont.outlined);
      expect(icons[1].color, _theme.colors.onSurfaceVariant);
      // The unselected item's indicator is drawn at no width.
      expect(_indicatorOf(tester, const ValueKey('explore')).width, 0);
    });

    testWidgets('the pill grows from the centre on the default spatial '
        'spring', (tester) async {
      await tester.pumpWidget(_app(const _Bar()));
      await tester.tap(find.byKey(const ValueKey('explore')));
      await tester.pump();
      const explore = ValueKey('explore');
      final widths = <double>[];
      for (var frame = 0; frame < 40; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        widths.add(_indicatorOf(tester, explore).width);
      }
      expect(widths.first, greaterThan(0));
      expect(widths.first, lessThan(56));
      // The spring (0.8 damping) overshoots, then settles on 56.
      expect(widths.reduce((a, b) => a > b ? a : b), greaterThan(56));
      await tester.pumpAndSettle();
      expect(_indicatorOf(tester, explore).width, 56);
      final centre = tester.getRect(find.byKey(explore)).center.dx;
      expect(_indicatorOf(tester, explore).center.dx, centre);
      expect(_textColor(tester, 'Explore'), _theme.colors.secondary);
    });

    testWidgets('a touch anywhere on an item selects it, and the ripple is '
        'the pill\'s', (tester) async {
      await tester.pumpWidget(_app(const _Bar()));
      final item = tester.getRect(find.byKey(const ValueKey('you')));
      // The far corner of the item, well outside its pill.
      await tester.tapAt(item.bottomRight - const Offset(4, 4));
      await tester.pumpAndSettle();
      expect(_textColor(tester, 'You'), _theme.colors.secondary);
      // The item's pressable is the pill-sized box.
      final pressable = tester.getRect(
        find.descendant(
          of: find.byKey(const ValueKey('you')),
          matching: find.byType(ExpressivePressable),
        ),
      );
      expect(pressable.size, const Size(56, 32));
    });

    testWidgets('each item is one selected-or-not tab to a screen reader', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_app(const _Bar()));
      final home = tester.getSemantics(find.byKey(const ValueKey('home')));
      expect(home.label, contains('Home'));
      expect(home, isSemantics(isSelected: true, hasTapAction: true));
      final explore = tester.getSemantics(
        find.byKey(const ValueKey('explore')),
      );
      expect(explore, isSemantics(isSelected: false, hasTapAction: true));
      semantics.dispose();
    });

    testWidgets('a disabled item dims and does not select', (tester) async {
      await tester.pumpWidget(
        _app(
          const _Bar(
            items: <ExpressiveNavItem>[
              ExpressiveNavItem(ExpressiveSymbols.home, 'Home'),
              ExpressiveNavItem(
                ExpressiveSymbols.payments,
                'Pay',
                enabled: false,
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Pay'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(
        _textColor(tester, 'Pay'),
        _theme.colors.onSurfaceVariant.withValues(alpha: 0.38),
      );
      expect(_textColor(tester, 'Home'), _theme.colors.secondary);
    });

    testWidgets('stands over the bottom inset, and grows with the text', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(const _Bar(), padding: const EdgeInsets.only(bottom: 24)),
      );
      expect(
        tester.getRect(find.byType(ExpressiveNavigationBar)).height,
        64 + 24,
      );
      await tester.pumpWidget(_app(const _Bar(), textScale: 2));
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byType(ExpressiveNavigationBar)).height,
        greaterThan(64),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('at text 2.0 a label too wide for its item prints smaller, '
        'its word whole, and every label with it', (tester) async {
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 390,
            child: ExpressiveNavigationBar(
              destinations: const <ExpressiveNavItem>[
                ExpressiveNavItem(ExpressiveSymbols.home, 'Home'),
                ExpressiveNavItem(ExpressiveSymbols.group, 'Shared'),
                ExpressiveNavItem(ExpressiveSymbols.hiking, 'Kit'),
                ExpressiveNavItem(ExpressiveSymbols.settings, 'Preferences'),
              ],
              selectedIndex: 0,
              onDestinationSelected: (_) {},
            ),
          ),
          textScale: 2,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final word = tester.renderObject<RenderParagraph>(
        find.text('Preferences'),
      );
      // One line: the word is laid out whole...
      expect(
        word.size.height,
        closeTo(word.getMaxIntrinsicHeight(double.infinity), 0.01),
      );
      // ...and drawn within its quarter of the bar, smaller than it would
      // be: every label of the bar at that one size.
      final drawn = tester.getRect(find.text('Preferences'));
      expect(drawn.width, lessThanOrEqualTo(390 / 4 + 0.01));
      expect(drawn.height, lessThan(word.size.height));
      for (final label in ['Home', 'Shared', 'Kit']) {
        expect(
          tester.getRect(find.text(label)).height,
          closeTo(drawn.height, 0.01),
          reason: label,
        );
      }
    });
  });

  group('the navigation rail', () {
    testWidgets('expanded, it is as wide as its labels need, 220 to 360dp; '
        'the items flush, each indicator 20dp in round the icon and label', (
      tester,
    ) async {
      Future<Rect> pump(List<ExpressiveNavItem> items) async {
        await tester.pumpWidget(
          _app(
            SizedBox(
              height: 600,
              child: ExpressiveNavigationRail(
                expanded: true,
                destinations: items,
                selectedIndex: 1,
                onDestinationSelected: (_) {},
              ),
            ),
            padding: const EdgeInsets.only(top: 24),
          ),
        );
        await tester.pumpAndSettle();
        return tester.getRect(find.byType(ExpressiveNavigationRail));
      }

      // Short labels: the 220dp floor (WideNavigationRail's expanded
      // minimum width).
      final rail = await pump(_items);
      expect(rail.width, 220);
      final indicator = _indicatorOf(tester, const ValueKey('explore'));
      // ItemHorizontalPadding 20; the expanded indicator 16dp either side
      // of icon and label, (56 − 24) / 2 = 16dp above and below the icon.
      expect(indicator.left - rail.left, 20);
      expect(indicator.height, 56);
      final label = tester.getRect(find.text('Explore'));
      expect(label.left - indicator.left, 16 + 24 + 8);
      expect(indicator.right, lessThanOrEqualTo(rail.right - 20));
      // 44dp below the top inset, then the items one under another.
      final home = _indicatorOf(tester, const ValueKey('home'));
      expect(home.top, 24 + 44);
      expect(indicator.top, home.bottom);
      // The selected label stands inside the indicator in the icon's colour
      // (as the bar's start-icon item's does): onSecondaryContainer.
      expect(_textColor(tester, 'Explore'), _theme.colors.onSecondaryContainer);
      // A long label widens it, never past 360dp.
      final long = await pump(<ExpressiveNavItem>[
        ..._items,
        const ExpressiveNavItem(
          ExpressiveSymbols.settings,
          'Notifications and privacy settings for every trip',
        ),
      ]);
      expect(long.width, 360);
      expect(tester.takeException(), isNull);
    });

    testWidgets('at compact density (the desktop default) the label keeps '
        'its distance: 8dp from the icon expanded, 4dp under the pill '
        'collapsed', (tester) async {
      Future<void> pump({required bool expanded}) async {
        await tester.pumpWidget(
          _app(
            SizedBox(
              height: 600,
              child: ExpressiveNavigationRail(
                expanded: expanded,
                destinations: _items,
                selectedIndex: 1,
                onDestinationSelected: (_) {},
              ),
            ),
            theme: _theme.copyWith(density: ExpressiveDensity.compact),
          ),
        );
        await tester.pumpAndSettle();
      }

      await pump(expanded: true);
      final wide = tester.getRect(find.text('Explore'));
      expect(wide.left - _iconRect(tester, ExpressiveSymbols.explore).right, 8);
      await pump(expanded: false);
      final under = tester.getRect(find.text('Explore'));
      expect(
        under.top - _indicatorOf(tester, const ValueKey('explore')).bottom,
        4,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('expanded, a focused item rings the inside of its pill: '
        'whole beside a selected neighbour, and nothing spills into it', (
      tester,
    ) async {
      const key = ValueKey<String>('rail');
      await tester.pumpWidget(
        _app(
          RepaintBoundary(
            key: key,
            child: SizedBox(
              height: 400,
              child: ExpressiveNavigationRail(
                expanded: true,
                destinations: _items,
                selectedIndex: 1,
                onDestinationSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(key),
      );
      Future<ByteData> shot() async => (await tester.runAsync(() async {
        final image = await boundary.toImage();
        final data = await image.toByteData();
        image.dispose();
        return data!;
      }))!;
      int pixel(ByteData data, Offset at) => data.getUint32(
        (at.dy.floor() * boundary.size.width.round() + at.dx.floor()) * 4,
      );
      final idle = await shot();
      // Keyboard focus on the first item: the traditional highlight, and the
      // node just inside its ink's own Focus.
      FocusNode? node;
      tester
          .element(
            find
                .descendant(
                  of: find
                      .descendant(
                        of: find.byKey(const ValueKey('home')),
                        matching: find.byWidgetPredicate(
                          (w) => w is InkResponse,
                        ),
                      )
                      .first,
                  matching: find.byType(Focus),
                )
                .first,
          )
          .visitChildren(
            (child) => node ??= Focus.maybeOf(child, createDependency: false),
          );
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );
      node!.requestFocus();
      await tester.pumpAndSettle();
      expect(node!.hasPrimaryFocus, isTrue);
      final focused = await shot();
      // The pills as pressed: an unselected item's indicator is drawn at
      // no width until it is chosen, its pressable is the whole pill.
      Rect pill(String key) => tester.getRect(
        find
            .descendant(
              of: find.byKey(ValueKey(key)),
              matching: find.byType(ExpressivePressable),
            )
            .first,
      );
      final home = pill('home');
      final explore = pill('explore');
      expect(explore.top, home.bottom, reason: 'the items stand flush');
      final c = _theme.colors.secondary;
      int byte(double v) => (v * 255).round();
      final ring =
          byte(c.r) << 24 | byte(c.g) << 16 | byte(c.b) << 8 | byte(c.a);
      // The ring's centre line, half the stroke inside the pill.
      final half = ExpressiveFocusRing.thickness / 2;
      for (final at in <Offset>[
        Offset(home.center.dx, home.top + half),
        Offset(home.center.dx, home.bottom - half),
        Offset(home.left + half, home.center.dy),
        Offset(home.right - half, home.center.dy),
      ]) {
        expect(
          pixel(focused, at).toRadixString(16),
          ring.toRadixString(16),
          reason: 'the ring at $at',
        );
      }
      // Below the pill, in the selected neighbour's: as it was.
      for (final dy in <double>[1, 3, 5]) {
        final at = Offset(home.center.dx, home.bottom + dy);
        expect(pixel(focused, at), pixel(idle, at), reason: 'at $at');
      }
      expect(tester.takeException(), isNull);
      // Drawn pixels are the rasterizer's, as a golden's: macOS runs it.
    }, tags: const ['goldens']);

    testWidgets('the drawer raises the expanded rail from the start edge '
        'over a scrim, and returns the destination chosen', (tester) async {
      int? chosen = -1;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => ExpressiveHost(
            light: _theme,
            brightness: Brightness.light,
            child: child!,
          ),
          home: Builder(
            builder: (context) => Center(
              child: GestureDetector(
                onTap: () async =>
                    chosen = await showExpressiveNavigationDrawer(
                      context,
                      destinations: _items,
                      selectedIndex: 0,
                    ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final rail = tester.getRect(find.byType(ExpressiveNavigationRail));
      expect(rail.topLeft, Offset.zero);
      expect(rail.width, 220);
      expect(
        rail.height,
        tester.view.physicalSize.height / tester.view.devicePixelRatio,
      );
      await tester.tap(find.byKey(const ValueKey('explore')));
      await tester.pumpAndSettle();
      expect(chosen, 1);
      expect(find.byType(ExpressiveNavigationRail), findsNothing);
      // The scrim dismisses it with no choice.
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tapAt(Offset(rail.right + 40, 40));
      await tester.pumpAndSettle();
      expect(chosen, isNull);
      expect(find.byType(ExpressiveNavigationRail), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets("a drawer's indicator spans the drawer 12dp in from its "
        "edges, its count at the row's end clear of the words", (tester) async {
      for (final density in const [
        ExpressiveDensity.standard,
        ExpressiveDensity.comfortable,
        ExpressiveDensity.compact,
      ]) {
        await tester.pumpWidget(
          _app(
            theme: _theme.copyWith(density: density),
            SizedBox(
              height: 600,
              child: ExpressiveNavigationDrawer(
                destinations: const <ExpressiveNavItem>[
                  ExpressiveNavItem(
                    ExpressiveSymbols.home,
                    'Chats',
                    key: ValueKey('chats'),
                    badge: ExpressiveBadge(label: '12'),
                  ),
                  ExpressiveNavItem(
                    ExpressiveSymbols.person,
                    'People',
                    key: ValueKey('people'),
                  ),
                ],
                selectedIndex: 0,
                onDestinationSelected: (_) {},
              ),
            ),
          ),
        );
        final drawer = tester.getRect(find.byType(ExpressiveNavigationRail));
        for (final key in const [ValueKey('chats'), ValueKey('people')]) {
          final row = tester.getRect(find.byKey(key));
          expect(row.left - drawer.left, 12, reason: '$key $density');
          expect(drawer.right - row.right, 12, reason: '$key $density');
        }
        final chosen = _indicatorOf(tester, const ValueKey('chats'));
        expect(chosen.left - drawer.left, 12);
        expect(drawer.right - chosen.right, 12);
        final badge = tester.getRect(find.byType(ExpressiveBadge));
        final words = tester.getRect(find.text('Chats'));
        final glyph = tester.getRect(find.byIcon(ExpressiveSymbols.home));
        expect(badge.left, greaterThan(words.right));
        expect(badge.left, greaterThan(glyph.right));
        expect(chosen.right - badge.right, lessThanOrEqualTo(24));
        expect(badge.center.dy, closeTo(chosen.center.dy, 1));
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('is 96dp of surface; the header, then items 44dp below the '
        'top inset, 64dp tall and 4dp apart', (tester) async {
      await tester.pumpWidget(
        _app(
          SizedBox(
            height: 600,
            child: ExpressiveNavigationRail(
              destinations: _items,
              selectedIndex: 1,
              onDestinationSelected: (_) {},
            ),
          ),
          padding: const EdgeInsets.only(top: 24),
        ),
      );
      final rail = tester.getRect(find.byType(ExpressiveNavigationRail));
      expect(rail.width, 96);
      final home = tester.getRect(find.byKey(const ValueKey('home')));
      expect(home.top, 24 + 44);
      expect(home.size, const Size(96, 64));
      final explore = tester.getRect(find.byKey(const ValueKey('explore')));
      expect(explore.top, home.bottom + 4);
      // The indicator: 56×32, 20dp in. NavigationItem's box centres the
      // 52dp layout (32 + 4 + a 16dp label line) in TopIconItemMinHeight:
      // (64 − 52) / 2 = 6dp down.
      final indicator = _indicatorOf(tester, const ValueKey('explore'));
      expect(indicator.size, const Size(56, 32));
      expect(indicator.topLeft - explore.topLeft, const Offset(20, 6));
      final label = tester.getRect(find.text('Explore'));
      // 6 + 4 + 24 + 4 + 4.
      expect(label.top - explore.top, 42);
      expect(_textColor(tester, 'Explore'), _theme.colors.secondary);
    });

    testWidgets('its header stands above the items, 40dp over the first', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SizedBox(
            height: 600,
            child: ExpressiveNavigationRail(
              destinations: _items,
              selectedIndex: 0,
              onDestinationSelected: (_) {},
              header: const SizedBox(
                key: ValueKey('header'),
                width: 56,
                height: 56,
              ),
            ),
          ),
        ),
      );
      final header = tester.getRect(find.byKey(const ValueKey('header')));
      final home = tester.getRect(find.byKey(const ValueKey('home')));
      expect(header.top, 44);
      expect(home.top - header.bottom, 40);
    });
  });

  group('tabs', () {
    Widget tabs({
      ExpressiveTabBarVariant variant = ExpressiveTabBarVariant.primary,
      bool scrollable = false,
      List<ExpressiveTab>? items,
      int selected = 0,
      ValueChanged<int>? onSelected,
    }) => SizedBox(
      width: 408,
      child: ExpressiveTabBar(
        tabs:
            items ??
            const <ExpressiveTab>[
              ExpressiveTab(label: 'Flights', key: ValueKey('t0')),
              ExpressiveTab(label: 'Hotels', key: ValueKey('t1')),
              ExpressiveTab(label: 'Cars', key: ValueKey('t2')),
            ],
        selectedIndex: selected,
        onChanged: onSelected ?? (_) {},
        variant: variant,
        scrollable: scrollable,
      ),
    );

    Rect indicator(WidgetTester tester) => tester.getRect(
      find
          .descendant(
            of: find.byType(ExpressiveTabBar),
            matching: find.byWidgetPredicate(
              (w) =>
                  (w is ColoredBox && w.color == _theme.colors.primary) ||
                  (w is DecoratedBox &&
                      (w.decoration as ShapeDecoration?)?.color ==
                          _theme.colors.primary),
            ),
          )
          .first,
    );

    testWidgets('at text 2.0 a word too wide for its tab prints whole', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          tabs(
            items: const <ExpressiveTab>[
              ExpressiveTab(label: 'Upcoming'),
              ExpressiveTab(label: 'Saved'),
              ExpressiveTab(label: 'Past'),
              ExpressiveTab(label: 'Wishlist'),
            ],
          ),
          textScale: 2,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final word = tester.renderObject<RenderParagraph>(find.text('Upcoming'));
      expect(
        word.size.height,
        closeTo(word.getMaxIntrinsicHeight(double.infinity), 0.01),
      );
      // The row's labels print at one size: "Upcoming" shrinks them alike.
      final printed = [
        for (final label in ['Upcoming', 'Saved', 'Past', 'Wishlist'])
          tester.getRect(find.text(label)).height,
      ];
      for (final height in printed) {
        expect(height, closeTo(printed.first, 0.01));
      }
    });

    testWidgets('a text tab stands its badge after the label, never over a '
        'letter', (tester) async {
      // The live example's "Mentions" tab wore its count over "ns": BadgedBox
      // places a badge 12dp in over an icon's corner.
      for (final variant in ExpressiveTabBarVariant.values) {
        await tester.pumpWidget(
          _app(
            tabs(
              variant: variant,
              items: const <ExpressiveTab>[
                ExpressiveTab(label: 'Overview'),
                ExpressiveTab(
                  label: 'Mentions',
                  badge: ExpressiveBadge(label: '2'),
                ),
                ExpressiveTab(label: 'Done', badge: ExpressiveBadge()),
              ],
            ),
          ),
        );
        for (final label in ['Mentions', 'Done']) {
          final word = tester.getRect(find.text(label));
          final badge = tester.getRect(
            find.descendant(
              of: find
                  .ancestor(of: find.text(label), matching: find.byType(Row))
                  .first,
              matching: find.byType(ExpressiveBadge),
            ),
          );
          expect(
            badge.left,
            greaterThanOrEqualTo(word.right),
            reason: '${variant.name} $label',
          );
          // The word is drawn by its capitals on the tab's middle
          // (DesignCapCenter), its line box under a pixel and a half from
          // where it is laid out, where the badge stands.
          expect(
            badge.top,
            closeTo(word.top, 1.5),
            reason: '${variant.name} $label',
          );
        }
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('primary: 48dp, the indicator 3dp under the label, as wide as '
        'it', (tester) async {
      await tester.pumpWidget(_app(tabs()));
      final row = tester.getRect(find.byType(ExpressiveTabBar));
      expect(row.height, 48);
      final tab = tester.getRect(find.byKey(const ValueKey('t0')));
      expect(tab.width, 136);
      final label = tester.getRect(find.text('Flights'));
      final bar = indicator(tester);
      expect(bar.height, 3);
      expect(bar.bottom, row.bottom);
      expect(bar.width, closeTo(label.width, 1));
      expect(bar.center.dx, closeTo(tab.center.dx, 0.5));
      // Tab's column fills the tab and centres its content: every label
      // stands at its tab's centre, over the indicator.
      for (final (key, text) in const [
        ('t0', 'Flights'),
        ('t1', 'Hotels'),
        ('t2', 'Cars'),
      ]) {
        final t = tester.getRect(find.byKey(ValueKey(key)));
        final l = tester.getRect(find.text(text));
        expect(l.center.dx, closeTo(t.center.dx, 0.5), reason: text);
      }
      expect(label.center.dx, closeTo(bar.center.dx, 0.5));
      expect(_textColor(tester, 'Flights'), _theme.colors.primary);
      expect(_textColor(tester, 'Hotels'), _theme.colors.onSurfaceVariant);
    });

    testWidgets('secondary: the indicator spans the tab; the selected label '
        'onSurface', (tester) async {
      await tester.pumpWidget(
        _app(tabs(variant: ExpressiveTabBarVariant.secondary, selected: 1)),
      );
      final tab = tester.getRect(find.byKey(const ValueKey('t1')));
      final bar = indicator(tester);
      expect(bar.left, tab.left);
      expect(bar.width, tab.width);
      expect(_textColor(tester, 'Hotels'), _theme.colors.onSurface);
    });

    testWidgets('an icon-and-label tab is 72dp', (tester) async {
      await tester.pumpWidget(
        _app(
          tabs(
            items: const <ExpressiveTab>[
              ExpressiveTab(label: 'Flights', icon: ExpressiveSymbols.flight),
              ExpressiveTab(label: 'Hotels', icon: ExpressiveSymbols.hotel),
            ],
          ),
        ),
      );
      expect(tester.getRect(find.byType(ExpressiveTabBar)).height, 72);
      final icon = tester.getRect(find.byIcon(ExpressiveSymbols.flight));
      final label = tester.getRect(find.text('Flights'));
      expect(icon.bottom, lessThan(label.top));
      final tab = tester.getRect(
        find.ancestor(
          of: find.text('Flights'),
          matching: find.byType(ExpressivePressable),
        ),
      );
      expect(icon.center.dx, closeTo(tab.center.dx, 0.5));
      expect(label.center.dx, closeTo(tab.center.dx, 0.5));
    });

    testWidgets('the indicator slides to a new tab on the spatial spring', (
      tester,
    ) async {
      var selected = 0;
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) => tabs(
              selected: selected,
              onSelected: (index) => setState(() => selected = index),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final from = indicator(tester).center.dx;
      await tester.tap(find.byKey(const ValueKey('t2')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 48));
      final mid = indicator(tester).center.dx;
      final to = tester.getRect(find.byKey(const ValueKey('t2'))).center.dx;
      expect(mid, greaterThan(from));
      expect(mid, lessThan(to));
      await tester.pumpAndSettle();
      expect(indicator(tester).center.dx, closeTo(to, 0.5));
      expect(_textColor(tester, 'Cars'), _theme.colors.primary);
    });

    testWidgets('scrollable: tabs 90dp at least, 52dp in, and the selected '
        'one scrolls to the middle', (tester) async {
      const labels = <String>[
        'All',
        'Breakfast',
        'Lunch',
        'Dinner',
        'Desserts',
        'Drinks',
        'Snacks',
        'Vegan',
      ];
      var selected = 0;
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) => tabs(
              scrollable: true,
              selected: selected,
              onSelected: (index) => setState(() => selected = index),
              items: <ExpressiveTab>[
                for (final label in labels)
                  ExpressiveTab(label: label, key: ValueKey(label)),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final all = tester.getRect(find.byKey(const ValueKey('All')));
      expect(all.left, 52);
      expect(all.width, 90);
      // 'All' is narrower than the 90dp minimum: it centres across it.
      expect(
        tester.getRect(find.text('All')).center.dx,
        closeTo(all.center.dx, 0.5),
      );
      // Lunch (the third tab) scrolls to the middle of the 408dp row.
      await tester.tap(find.byKey(const ValueKey('Lunch')));
      await tester.pumpAndSettle();
      final lunch = tester.getRect(find.byKey(const ValueKey('Lunch')));
      expect(lunch.center.dx, closeTo(204, 1));
      expect(indicator(tester).center.dx, closeTo(lunch.center.dx, 0.5));
      expect(tester.takeException(), isNull);
    });

    // The coordinator's walk at 1440: three tabs split a 928dp column into
    // thirds. From 600 they keep to their labels from the start edge, as
    // Material's TabAlignment.start lays them out; on a phone (the tests
    // above) they share the width.
    testWidgets('from 600: fixed tabs keep to their labels from the start '
        'edge, the row and its divider the column wide', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1440, 900);
      addTearDown(tester.view.reset);
      for (final variant in ExpressiveTabBarVariant.values) {
        await tester.pumpWidget(
          _app(
            Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(size: const Size(1440, 900)),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: 928,
                    child: ExpressiveTabBar(
                      tabs: const <ExpressiveTab>[
                        ExpressiveTab(label: 'Flights', key: ValueKey('t0')),
                        ExpressiveTab(label: 'Hotels', key: ValueKey('t1')),
                        ExpressiveTab(label: 'Cars', key: ValueKey('t2')),
                      ],
                      selectedIndex: 0,
                      onChanged: (_) {},
                      variant: variant,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final row = tester.getRect(find.byType(ExpressiveTabBar));
        expect(row.width, 928, reason: variant.name);
        var left = row.left;
        for (final (key, text) in const [
          ('t0', 'Flights'),
          ('t1', 'Hotels'),
          ('t2', 'Cars'),
        ]) {
          final tab = tester.getRect(find.byKey(ValueKey(key)));
          final label = tester.getRect(find.text(text));
          expect(
            tab.left,
            closeTo(left, 0.01),
            reason: '${variant.name} $text',
          );
          // Its label and 16dp each side, 90dp at least.
          expect(
            tab.width,
            closeTo(math.max(90, label.width + 32), 1),
            reason: '${variant.name} $text',
          );
          expect(label.center.dx, closeTo(tab.center.dx, 0.5));
          left = tab.right;
        }
        // The tabs keep to their labels: together far short of the row, not
        // sharing its width out.
        expect(left - row.left, lessThan(row.width / 2), reason: variant.name);
        final first = tester.getRect(find.byKey(const ValueKey('t0')));
        expect(indicator(tester).center.dx, closeTo(first.center.dx, 0.5));
        expect(indicator(tester).bottom, row.bottom);
        expect(tester.takeException(), isNull);
      }
    });
  });
}

const ExpressiveNavItem _extra = ExpressiveNavItem(
  ExpressiveSymbols.settings,
  'Settings',
);
