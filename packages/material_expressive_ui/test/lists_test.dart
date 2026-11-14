/// The lists family: the list item's heights, slots and alignment from
/// `ListTokens` (Compose's `InteractiveListItemMeasurePolicy`), the
/// segmented section's corners and gap, colours and semantics by kind,
/// dividers and section headers, the reorderable list, swipe to dismiss and
/// swipe actions (Compose's anchored drag), the accordion and the grid.
/// Ports Cody v2's row-group and swipe-action tests (foundation_test.dart,
/// foundation_controls_test.dart) to Expressive.
library;

import 'package:material_ui/material_ui.dart' show InkResponse, NoSplash, Theme;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/divider_tokens.g.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/list_tokens.g.dart';

import 'support/pressable.dart';

final ExpressiveThemeData _theme = ExpressiveThemeData.preset(
  'baseline',
  Brightness.light,
);

Widget _app(
  Widget child, {
  TextDirection direction = TextDirection.ltr,
  double scale = 1,
  double width = 360,
}) => ExpressiveHost(
  light: _theme,
  brightness: Brightness.light,
  child: Directionality(
    textDirection: direction,
    child: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(scale)),
      child: Shortcuts(
        shortcuts: WidgetsApp.defaultShortcuts,
        child: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: width,
            child: SingleChildScrollView(child: child),
          ),
        ),
      ),
    ),
  ),
);

/// The container an item paints: the surface inside the item.
ExpressiveSurface _surface(WidgetTester tester, Finder item) =>
    tester.widget<ExpressiveSurface>(
      find.descendant(of: item, matching: find.byType(ExpressiveSurface)).first,
    );

/// The four corner radii (dp) of the item's container, top-start first.
List<double> _corners(WidgetTester tester, Finder item) {
  final shape = _surface(tester, item).shape as ExpressiveCornerBorder;
  return <double>[
    shape.topStart.dp,
    shape.topEnd.dp,
    shape.bottomEnd.dp,
    shape.bottomStart.dp,
  ];
}

void main() {
  group('list item', () {
    testWidgets('one, two and three lines take the token heights', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const Column(
            children: <Widget>[
              ExpressiveListTile(key: Key('one'), title: Text('Wi-Fi')),
              ExpressiveListTile(
                key: Key('two'),
                title: Text('Wi-Fi'),
                subtitle: Text('Home'),
              ),
              ExpressiveListTile(
                key: Key('overline'),
                overline: Text('Network'),
                title: Text('Wi-Fi'),
                subtitle: Text('Home'),
              ),
              ExpressiveListTile(
                key: Key('wraps'),
                title: Text('Storage'),
                subtitle: Text(
                  'Photos and videos take the most room on this phone',
                ),
              ),
            ],
          ),
        ),
      );
      double height(String key) => tester.getSize(find.byKey(Key(key))).height;
      expect(height('one'), ListTokens.itemOneLineContainerHeight);
      expect(height('two'), ListTokens.itemTwoLineContainerHeight);
      expect(height('overline'), ListTokens.itemThreeLineContainerHeight);
      // Supporting text that wraps counts as a third line.
      expect(
        height('wraps'),
        greaterThanOrEqualTo(ListTokens.itemThreeLineContainerHeight),
      );
      expect(tester.takeException(), isNull);
    });

    for (final direction in TextDirection.values) {
      testWidgets('slots sit at the token spaces in $direction', (
        tester,
      ) async {
        await tester.pumpWidget(
          _app(
            const ExpressiveListTile(
              key: Key('item'),
              title: Text('Wi-Fi'),
              leading: SizedBox.square(key: Key('lead'), dimension: 24),
              trailing: SizedBox.square(key: Key('trail'), dimension: 24),
            ),
            direction: direction,
          ),
        );
        final item = tester.getRect(find.byKey(const Key('item')));
        final lead = tester.getRect(find.byKey(const Key('lead')));
        final trail = tester.getRect(find.byKey(const Key('trail')));
        final text = tester.getRect(find.text('Wi-Fi'));
        final ltr = direction == TextDirection.ltr;
        double fromStart(Rect r) =>
            ltr ? r.left - item.left : item.right - r.right;
        double fromEnd(Rect r) =>
            ltr ? item.right - r.right : r.left - item.left;
        expect(fromStart(lead), ListTokens.itemLeadingSpace);
        expect(
          fromStart(text),
          ListTokens.itemLeadingSpace + 24 + ListTokens.itemBetweenSpace,
        );
        expect(fromEnd(trail), ListTokens.itemTrailingSpace);
        // One line centres its content.
        expect(lead.center.dy, closeTo(item.center.dy, 0.01));
      });
    }

    testWidgets('three lines top-align the content', (tester) async {
      await tester.pumpWidget(
        _app(
          const ExpressiveListTile(
            key: Key('item'),
            overline: Text('Recipe'),
            title: Text('Charred corn'),
            subtitle: Text('Lime and mint'),
            leading: SizedBox.square(key: Key('lead'), dimension: 24),
          ),
        ),
      );
      final item = tester.getRect(find.byKey(const Key('item')));
      final lead = tester.getRect(find.byKey(const Key('lead')));
      expect(lead.top - item.top, ListTokens.itemTopSpace);
    });

    testWidgets('selectable: radio semantics, selected colours and corners', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        _app(
          ExpressiveListTile.selectable(
            key: const Key('item'),
            title: const Text('Express'),
            selected: true,
            onTap: () => taps++,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final item = find.byKey(const Key('item'));
      expect(_surface(tester, item).color, _theme.colors.secondaryContainer);
      expect(
        _corners(tester, item),
        everyElement(_theme.shapes.large.topStart.dp),
      );
      expect(
        tester.getSemantics(find.text('Express')),
        matchesSemantics(
          label: 'Express',
          hasCheckedState: true,
          isChecked: true,
          isInMutuallyExclusiveGroup: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      await tester.tap(item);
      expect(taps, 1);
      semantics.dispose();
    });

    testWidgets('toggleable reports the next value; disabled reports none', (
      tester,
    ) async {
      final reported = <bool>[];
      await tester.pumpWidget(
        _app(
          Column(
            children: <Widget>[
              ExpressiveListTile.toggleable(
                title: const Text('Passport'),
                value: true,
                onChanged: reported.add,
              ),
              ExpressiveListTile.toggleable(
                title: const Text('Charger'),
                value: false,
                enabled: false,
                onChanged: reported.add,
              ),
            ],
          ),
        ),
      );
      await tester.tap(pressableOf(find.text('Passport')));
      await tester.tap(find.text('Charger'), warnIfMissed: false);
      expect(reported, <bool>[false]);
    });

    testWidgets('a control in a slot takes its own taps and keeps a node of '
        'its own (Compose: a child clickable)', (tester) async {
      final handle = tester.ensureSemantics();
      var opens = 0;
      var stars = 0;
      await tester.pumpWidget(
        _app(
          ExpressiveListTile(
            title: const Text('Lisbon'),
            trailing: ExpressiveIconButton(
              ExpressiveSymbols.star,
              onPressed: () => stars++,
              semanticLabel: 'Star',
            ),
            onTap: () => opens++,
          ),
        ),
      );
      await tester.tap(find.byType(ExpressiveIconButton));
      await tester.pumpAndSettle();
      expect((opens, stars), (0, 1));
      await tester.tapAt(tester.getCenter(find.text('Lisbon')));
      await tester.pumpAndSettle();
      expect((opens, stars), (1, 1));

      expect(
        tester.getSemantics(find.text('Lisbon')),
        isSemantics(label: 'Lisbon', isButton: true, hasTapAction: true),
      );
      final star = tester.getSemantics(find.byType(ExpressiveIconButton));
      expect(star.isMergedIntoParent, isFalse);
      expect(
        star,
        isSemantics(label: 'Star', isButton: true, hasTapAction: true),
      );
      handle.dispose();
    });

    testWidgets('a static item keeps a control inside a node of its own', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final kudos = <bool>[];
      await tester.pumpWidget(
        _app(
          ExpressiveListTile(
            title: const Text('Morning run'),
            trailing: ExpressiveIconToggleButton(
              ExpressiveSymbols.thumbUp,
              value: false,
              onChanged: kudos.add,
              semanticLabel: 'Give kudos',
            ),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.text('Morning run')).getSemanticsData().label,
        'Morning run',
      );
      final toggle = tester.getSemantics(
        find.byType(ExpressiveIconToggleButton),
      );
      expect(toggle.isMergedIntoParent, isFalse);
      expect(
        toggle,
        isSemantics(
          label: 'Give kudos',
          hasToggledState: true,
          hasTapAction: true,
        ),
      );
      await tester.tap(find.byType(ExpressiveIconToggleButton));
      expect(kudos, <bool>[true]);
      handle.dispose();
    });

    testWidgets('press rounds the corners to 16dp and back', (tester) async {
      await tester.pumpWidget(
        _app(
          ExpressiveListTile(
            key: const Key('item'),
            title: const Text('Wi-Fi'),
            onTap: () {},
          ),
        ),
      );
      final item = find.byKey(const Key('item'));
      expect(
        _corners(tester, item),
        everyElement(_theme.shapes.extraSmall.topStart.dp),
      );
      final gesture = await tester.startGesture(tester.getCenter(item));
      await tester.pumpAndSettle();
      expect(
        _corners(tester, item),
        everyElement(_theme.shapes.large.topStart.dp),
      );
      await gesture.up();
      await tester.pumpAndSettle();
      expect(
        _corners(tester, item),
        everyElement(_theme.shapes.extraSmall.topStart.dp),
      );
    });

    testWidgets('press feedback is the host pressable\'s own ink', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          ExpressiveListTile(
            key: const Key('item'),
            title: const Text('Wi-Fi'),
            onTap: () {},
          ),
        ),
      );
      final item = find.byKey(const Key('item'));
      final pressable = find.descendant(
        of: item,
        matching: find.byType(ExpressivePressable),
      );
      expect(pressable, findsOneWidget);
      // The one ink is the pressable's, on the host's splash factory:
      // nothing suppresses its ripple to paint another.
      final ink = find.descendant(of: item, matching: find.byType(InkResponse));
      expect(ink, findsOneWidget);
      expect(find.descendant(of: pressable, matching: ink), findsOneWidget);
      final splash = Theme.of(tester.element(ink)).splashFactory;
      expect(splash, Theme.of(tester.element(item)).splashFactory);
      expect(splash, isNot(NoSplash.splashFactory));
      // Held, the item paints no press layer of its own: nothing it hands
      // the pressable paints.
      final gesture = await tester.startGesture(tester.getCenter(item));
      await tester.pumpAndSettle();
      final content = tester.widget<ExpressivePressable>(pressable).child;
      expect(
        find.descendant(
          of: find.byWidget(content),
          matching: find.byType(CustomPaint),
        ),
        findsNothing,
      );
      await gesture.up();
      await tester.pumpAndSettle();
    });
  });

  group('section', () {
    testWidgets('segments: 16dp outer corners, 4dp inner, 2dp apart', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const ExpressiveListSection(
            children: <Widget>[
              ExpressiveListTile(key: Key('a'), title: Text('A')),
              ExpressiveListTile(key: Key('b'), title: Text('B')),
              ExpressiveListTile(key: Key('c'), title: Text('C')),
            ],
          ),
        ),
      );
      final outer = _theme.shapes.large.topStart.dp;
      final inner = _theme.shapes.extraSmall.topStart.dp;
      expect(_corners(tester, find.byKey(const Key('a'))), <double>[
        outer,
        outer,
        inner,
        inner,
      ]);
      expect(_corners(tester, find.byKey(const Key('b'))), everyElement(inner));
      expect(_corners(tester, find.byKey(const Key('c'))), <double>[
        inner,
        inner,
        outer,
        outer,
      ]);
      expect(
        tester.getTopLeft(find.byKey(const Key('b'))).dy -
            tester.getBottomLeft(find.byKey(const Key('a'))).dy,
        ListTokens.segmentedGap,
      );
    });

    testWidgets('a segmented group stands on surfaceContainer, a plain list '
        'on the page\'s surface', (tester) async {
      for (final segmented in <bool>[true, false]) {
        await tester.pumpWidget(
          _app(
            ExpressiveListSection(
              // A fresh group each time: a colour change animates.
              key: ValueKey(segmented),
              segmented: segmented,
              children: const <Widget>[
                ExpressiveListTile(key: Key('a'), title: Text('A')),
                ExpressiveListTile(key: Key('b'), title: Text('B')),
              ],
            ),
          ),
        );
        expect(
          _surface(tester, find.byKey(const Key('a'))).color,
          segmented ? _theme.colors.surfaceContainer : _theme.colors.surface,
          reason: segmented ? 'segmented' : 'plain',
        );
      }
    });

    testWidgets('a group of one is round on every corner', (tester) async {
      await tester.pumpWidget(
        _app(
          const ExpressiveListSection(
            children: <Widget>[
              ExpressiveListTile(key: Key('a'), title: Text('A')),
            ],
          ),
        ),
      );
      expect(
        _corners(tester, find.byKey(const Key('a'))),
        everyElement(_theme.shapes.large.topStart.dp),
      );
    });

    // Cody: 'selection group keeps content inset at $direction/$scale'.
    for (final direction in TextDirection.values) {
      for (final scale in <double>[1.0, 2.0]) {
        testWidgets(
          'selection group keeps content inset at $direction/$scale',
          (tester) async {
            var selected = 0;
            const groupKey = ValueKey<String>('selection-group');
            const logoKey = ValueKey<String>('payment-logo');
            await tester.pumpWidget(
              _app(
                StatefulBuilder(
                  builder: (context, setState) => ExpressiveListSection(
                    key: groupKey,
                    children: <Widget>[
                      ExpressiveListTile.selectable(
                        title: const Text('Home studio'),
                        subtitle: const Text(
                          '742 Evergreen Terrace, apartment 12, Springfield',
                        ),
                        selected: selected == 0,
                        onTap: () => setState(() => selected = 0),
                      ),
                      ExpressiveListTile.selectable(
                        title: const Text('Visa ending 4242'),
                        subtitle: const Text('Expires December 2029'),
                        leading: const SizedBox(
                          key: logoKey,
                          width: 32,
                          height: 20,
                        ),
                        selected: selected == 1,
                        onTap: () => setState(() => selected = 1),
                      ),
                    ],
                  ),
                ),
                direction: direction,
                scale: scale,
                width: 350,
              ),
            );
            final group = tester.getRect(find.byKey(groupKey));
            final plain = tester.getRect(find.text('Home studio'));
            final logo = tester.getRect(find.byKey(logoKey));
            // The section contributes exactly the list's 16dp leading space.
            for (final content in <Rect>[plain, logo]) {
              final inset = direction == TextDirection.ltr
                  ? content.left - group.left
                  : group.right - content.right;
              expect(inset, closeTo(ListTokens.itemLeadingSpace, 0.01));
            }
            expect(tester.takeException(), isNull);
            List<bool> states() => tester
                .widgetList<ExpressiveListTile>(find.byType(ExpressiveListTile))
                .map((item) => item.selected)
                .toList();
            expect(states(), <bool>[true, false]);
            await tester.tap(pressableOf(find.text('Visa ending 4242')));
            await tester.pumpAndSettle();
            expect(states(), <bool>[false, true]);
            await tester.tap(pressableOf(find.text('Home studio')));
            await tester.pumpAndSettle();
            expect(selected, 0);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }

    // Cody: 'row group owns its gutter and its dividers run full width'.
    testWidgets('row group owns its gutter and its dividers run full width', (
      tester,
    ) async {
      const groupKey = ValueKey<String>('group');
      await tester.pumpWidget(
        _app(
          const ExpressiveListSection(
            key: groupKey,
            segmented: false,
            divider: ExpressiveDividerInset.none,
            children: <Widget>[
              ExpressiveListTile(title: Text('First')),
              ExpressiveListTile(title: Text('Second')),
            ],
          ),
        ),
      );
      final group = tester.getRect(find.byKey(groupKey));
      // The gutter is the item's own: text starts 16 in from the group's
      // edge, and nothing is left for a draft to forget.
      expect(
        tester.getTopLeft(find.text('First')).dx,
        group.left + ListTokens.itemLeadingSpace,
      );
      // One full-bleed hairline between the two rows.
      final dividers = find.byType(ExpressiveDivider);
      expect(dividers, findsOneWidget);
      final line = tester.getRect(dividers);
      expect(line.left, group.left);
      expect(line.right, group.right);
      expect(line.height, DividerTokens.thickness);
      expect(tester.takeException(), isNull);
    });

    testWidgets('header is a heading in line with the items; footer below', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          const ExpressiveListSection(
            key: Key('group'),
            header: 'Network',
            footer: 'Only you can see this.',
            children: <Widget>[ExpressiveListTile(title: Text('Wi-Fi'))],
          ),
        ),
      );
      final group = tester.getRect(find.byKey(const Key('group')));
      expect(
        tester.getTopLeft(find.text('Network')).dx,
        group.left + ListTokens.itemLeadingSpace,
      );
      expect(
        tester.getSemantics(find.text('Network')),
        matchesSemantics(label: 'Network', isHeader: true),
      );
      expect(
        tester.getTopLeft(find.text('Only you can see this.')).dy,
        greaterThan(tester.getBottomLeft(find.text('Wi-Fi')).dy),
      );
      semantics.dispose();
    });
  });

  group('divider', () {
    testWidgets('insets by the list divider spaces', (tester) async {
      await tester.pumpWidget(
        _app(
          const Column(
            children: <Widget>[
              ExpressiveDivider(key: Key('full')),
              ExpressiveDivider(
                key: Key('start'),
                inset: ExpressiveDividerInset.start,
              ),
              ExpressiveDivider(
                key: Key('both'),
                inset: ExpressiveDividerInset.both,
              ),
            ],
          ),
        ),
      );
      Rect line(String key) => tester.getRect(
        find.descendant(
          of: find.byKey(Key(key)),
          matching: find.byType(ColoredBox),
        ),
      );
      expect(line('full').width, 360);
      expect(line('full').height, DividerTokens.thickness);
      expect(line('start').width, 360 - ListTokens.dividerLeadingSpace);
      expect(
        line('both').width,
        360 - ListTokens.dividerLeadingSpace - ListTokens.dividerTrailingSpace,
      );
      expect(
        tester
            .widget<ColoredBox>(
              find.descendant(
                of: find.byKey(const Key('full')),
                matching: find.byType(ColoredBox),
              ),
            )
            .color,
        _theme.colors.outlineVariant,
      );
    });
  });

  group('swipe', () {
    // Cody: 'swipe reveals multiple actions and full swipe is opt-in'.
    testWidgets('swipe reveals multiple actions and full swipe is opt-in', (
      tester,
    ) async {
      var archives = 0, deletes = 0;
      await tester.pumpWidget(
        _app(
          ExpressiveSwipeActions(
            trailing: <ExpressiveSwipeAction>[
              ExpressiveSwipeAction(
                label: 'Delete',
                icon: ExpressiveSymbols.delete,
                destructive: true,
                onPressed: () => deletes++,
              ),
              ExpressiveSwipeAction(
                label: 'Archive',
                icon: ExpressiveSymbols.archive,
                onPressed: () => archives++,
              ),
            ],
            child: const ExpressiveListTile(title: Text('Trip')),
          ),
        ),
      );
      await tester.drag(find.text('Trip'), const Offset(-600, 0));
      await tester.pumpAndSettle();
      expect(deletes, 0);
      await tester.tap(find.bySemanticsLabel('Archive'));
      await tester.pumpAndSettle();
      expect(archives, 1);
      expect(deletes, 0);
      // Tapping an action closes the row.
      expect(find.bySemanticsLabel('Archive'), findsNothing);
    });

    // Cody: 'full swipe invokes once and respects RTL leading edge'.
    testWidgets('full swipe invokes once and respects RTL leading edge', (
      tester,
    ) async {
      var calls = 0;
      await tester.pumpWidget(
        _app(
          ExpressiveSwipeActions(
            allowsFullSwipe: true,
            leading: <ExpressiveSwipeAction>[
              ExpressiveSwipeAction(
                label: 'Flag',
                icon: ExpressiveSymbols.flag,
                onPressed: () => calls++,
              ),
            ],
            child: const ExpressiveListTile(title: Text('Trip')),
          ),
          direction: TextDirection.rtl,
        ),
      );
      await tester.drag(find.text('Trip'), const Offset(-900, 0));
      await tester.pumpAndSettle();
      expect(calls, 1);
      // In RTL a swipe toward the right reveals nothing: no trailing actions.
      await tester.drag(find.text('Trip'), const Offset(900, 0));
      await tester.pumpAndSettle();
      expect(calls, 1);
    });

    // Cody: 'the dismissible deletes on a trailing-edge fling only'.
    testWidgets('the dismissible deletes on a trailing-edge fling only', (
      tester,
    ) async {
      var dismissed = 0;
      var rows = <String>['Weeknight ragu'];
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) => Column(
              children: <Widget>[
                for (final row in rows)
                  ExpressiveSwipeToDismiss(
                    key: ValueKey<String>(row),
                    onDismissed: (_) => setState(() {
                      dismissed += 1;
                      rows = <String>[];
                    }),
                    child: ExpressiveListTile(title: Text(row)),
                  ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // A leading-edge fling is not a delete: that gesture belongs to back.
      await tester.fling(
        find.text('Weeknight ragu'),
        const Offset(400, 0),
        1200,
      );
      await tester.pumpAndSettle();
      expect(dismissed, 0);

      await tester.fling(
        find.text('Weeknight ragu'),
        const Offset(-400, 0),
        1200,
      );
      await tester.pumpAndSettle();
      expect(dismissed, 1);
      expect(find.text('Weeknight ragu'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a short slow drag springs back; 56dp settles off', (
      tester,
    ) async {
      var dismissed = 0;
      await tester.pumpWidget(
        _app(
          ExpressiveSwipeToDismiss(
            onDismissed: (_) => dismissed++,
            child: const ExpressiveListTile(
              key: Key('row'),
              title: Text('Row'),
            ),
          ),
        ),
      );
      final start = tester.getTopLeft(find.byKey(const Key('row')));
      await tester.timedDrag(
        find.text('Row'),
        const Offset(-40, 0),
        const Duration(seconds: 2),
      );
      await tester.pumpAndSettle();
      expect(dismissed, 0);
      expect(tester.getTopLeft(find.byKey(const Key('row'))), start);
      await tester.timedDrag(
        find.text('Row'),
        const Offset(-80, 0),
        const Duration(seconds: 2),
      );
      await tester.pumpAndSettle();
      expect(dismissed, 1);
    });
  });

  group('reorderable list', () {
    const stops = <String>['A', 'B', 'C'];

    /// The stops in a reorderable list, each item clickable with [onOpen].
    Widget list(List<(int, int)> moves, {ValueChanged<String>? onOpen}) => _app(
      Localizations(
        locale: const Locale('en'),
        delegates: const <LocalizationsDelegate<Object>>[
          DefaultWidgetsLocalizations.delegate,
        ],
        child: SizedBox(
          height: 400,
          child: Overlay(
            initialEntries: <OverlayEntry>[
              OverlayEntry(
                builder: (context) => ExpressiveReorderableListView(
                  itemCount: stops.length,
                  onReorder: (from, to) => moves.add((from, to)),
                  itemBuilder: (context, i) => ExpressiveListTile(
                    key: ValueKey<String>(stops[i]),
                    title: Text(stops[i]),
                    trailing: ExpressiveReorderHandle(index: i),
                    onTap: onOpen == null ? null : () => onOpen(stops[i]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    testWidgets('dragging a handle reports the move', (tester) async {
      final moves = <(int, int)>[];
      await tester.pumpWidget(list(moves));
      final handle = find.byType(ExpressiveReorderHandle).first;
      final gesture = await tester.startGesture(tester.getCenter(handle));
      await tester.pump();
      await gesture.moveBy(const Offset(0, 80));
      await tester.pump();
      // While dragged the proxy lifts in tertiaryContainer.
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is ExpressiveSurface &&
              w.color == _theme.colors.tertiaryContainer,
        ),
        findsWidgets,
      );
      await gesture.moveBy(const Offset(0, 80));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(moves, hasLength(1));
      expect(moves.single.$1, 0);
      expect(moves.single.$2, greaterThan(0));
    });

    testWidgets('a clickable item\'s handle drags it; a tap elsewhere opens '
        'it', (tester) async {
      final moves = <(int, int)>[];
      final opened = <String>[];
      await tester.pumpWidget(list(moves, onOpen: opened.add));
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(ExpressiveReorderHandle).first),
      );
      await tester.pump();
      await gesture.moveBy(const Offset(0, 80));
      await tester.pump();
      await gesture.moveBy(const Offset(0, 80));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(moves, hasLength(1));
      expect(moves.single.$1, 0);
      expect(opened, isEmpty);

      await tester.tap(find.text('B'));
      await tester.pumpAndSettle();
      expect(opened, <String>['B']);
    });
  });

  group('accordion', () {
    testWidgets('opens and closes, announcing its state', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          const ExpressiveDisclosure(
            title: Text('Shipping'),
            child: Text('Ships in two days.', key: Key('body')),
          ),
        ),
      );
      expect(find.byKey(const Key('body')), findsNothing);
      expect(
        tester.getSemantics(find.text('Shipping')),
        matchesSemantics(
          label: 'Shipping',
          hasExpandedState: true,
          isExpanded: false,
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      // Tap the header's pressable: its ink lies over the text.
      final header = find.ancestor(
        of: find.text('Shipping'),
        matching: find.byType(ExpressivePressable),
      );
      await tester.tap(header);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('body')), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(const Key('body'))).dy,
        greaterThan(tester.getBottomLeft(find.text('Shipping')).dy),
      );
      await tester.tap(header);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('body')), findsNothing);
      semantics.dispose();
    });
  });

  group('grid', () {
    testWidgets('adaptive columns fit the width; fixed columns split it', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          Column(
            children: <Widget>[
              ExpressiveGrid(
                shrinkWrap: true,
                minItemWidth: 100,
                itemCount: 6,
                itemBuilder: (context, i) => SizedBox(key: Key('a$i')),
              ),
              ExpressiveGrid(
                shrinkWrap: true,
                itemCount: 2,
                itemBuilder: (context, i) => SizedBox(key: Key('f$i')),
              ),
            ],
          ),
        ),
      );
      // (360 + 8) / (100 + 8) = 3.4: three columns of (360 − 16) / 3.
      final cell = tester.getSize(find.byKey(const Key('a0')));
      expect(cell.width, closeTo((360 - 2 * ExpressiveSpacing.s8) / 3, 0.01));
      expect(
        tester.getTopLeft(find.byKey(const Key('a3'))).dy,
        tester.getBottomLeft(find.byKey(const Key('a0'))).dy +
            ExpressiveSpacing.s8,
      );
      expect(
        tester.getSize(find.byKey(const Key('f0'))).width,
        closeTo((360 - ExpressiveSpacing.s8) / 2, 0.01),
      );
    });
  });
}
