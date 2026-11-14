/// Menus and popovers: Compose's expressive `DropdownMenuPopup`, its groups
/// and items, geometry and colours from the tokens, the popup's placement
/// and spring motion, the themes it carries onto the root overlay, a
/// popover leaving the system back to a menu held open in it, and the Cody
/// v2 context-menu and popover tests ported (decision F14).
library;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/behavior.g.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/segmented_menu_tokens.g.dart';

final ExpressiveThemeData bloom = ExpressiveThemeData.preset(
  'bloom',
  Brightness.light,
);

/// An app the way a generated app runs: Expressive's host around the
/// router's navigator, a scrolling page.
Widget host(
  WidgetBuilder builder, {
  double scale = 1,
  TextDirection direction = TextDirection.ltr,
  MediaQueryData? media,
}) => MaterialApp(
  builder: (context, app) =>
      ExpressiveHost(light: bloom, brightness: Brightness.light, child: app!),
  home: Builder(
    builder: (context) => MediaQuery(
      data: (media ?? MediaQuery.of(context)).copyWith(
        textScaler: TextScaler.linear(scale),
      ),
      child: Directionality(
        textDirection: direction,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Align(
                alignment: AlignmentDirectional.topStart,
                child: builder(context),
              ),
            ),
          ),
        ),
      ),
    ),
  ),
);

Finder get menu => find.byType(ExpressiveMenuSurface);

/// The drawn surface of the item labelled [label] (inside its 48dp touch
/// target).
Finder itemSurface(String label) => find
    .ancestor(of: find.text(label), matching: find.byType(ExpressiveSurface))
    .first;

void main() {
  testWidgets('a narrow bounded inline menu scrolls to its last action', (
    tester,
  ) async {
    var selected = false;
    await tester.pumpWidget(
      host(
        (context) => ExpressiveTheme(
          data: bloom,
          child: SizedBox(
            width: 120,
            height: 160,
            child: ExpressiveMenuSurface(
              groups: [
                ExpressiveMenuGroup([
                  ExpressiveMenuItem(
                    'First destination',
                    supportingText: 'A longer supporting line',
                    onPressed: () {},
                  ),
                  ExpressiveMenuItem(
                    'Second destination',
                    supportingText: 'A longer supporting line',
                    onPressed: () {},
                  ),
                  ExpressiveMenuItem(
                    'Last destination',
                    supportingText: 'A longer supporting line',
                    onPressed: () => selected = true,
                  ),
                ]),
              ],
            ),
          ),
        ),
        scale: 1.3,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Last destination'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Last destination'));
    await tester.pumpAndSettle();
    expect(selected, isTrue);
    expect(tester.takeException(), isNull);
  });

  // --- Cody v2 ports (F14) -------------------------------------------------

  testWidgets(
    'menu dismisses before invoking an action and disables null actions',
    (tester) async {
      var selected = '';
      var dismissedFirst = false;
      await tester.pumpWidget(
        host(
          (context) => ExpressiveMenu(
            entries: [
              const ExpressiveMenuItem('Unavailable'),
              ExpressiveMenuItem(
                'Rename',
                onPressed: () {
                  selected = 'rename';
                  // The menu is already on its way out: the page is current.
                  dismissedFirst = ModalRoute.of(context)!.isCurrent;
                },
              ),
            ],
            child: const Text('More'),
          ),
        ),
      );
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.text('Unavailable')),
        isSemantics(hasEnabledState: true, isEnabled: false),
      );
      await tester.tap(itemSurface('Unavailable'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(selected, '');
      expect(find.text('Rename'), findsOneWidget);
      await tester.tap(itemSurface('Rename'));
      expect(selected, 'rename');
      expect(dismissedFirst, isTrue);
      await tester.pumpAndSettle();
      expect(find.text('Rename'), findsNothing);
    },
  );

  testWidgets('context menu opens on hold without consuming child tap', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      host(
        (context) => ExpressiveMenu(
          trigger: ExpressiveMenuTrigger.longPress,
          entries: [ExpressiveMenuItem('Archive', onPressed: () {})],
          child: GestureDetector(
            onTap: () => taps++,
            child: const Text('Trip'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Trip'));
    expect(taps, 1);
    await tester.longPress(find.text('Trip'));
    await tester.pumpAndSettle();
    expect(find.text('Archive'), findsOneWidget);
    expect(taps, 1);
  });

  testWidgets('a menu open in a popover takes the first back; the popover '
      'stays up', (tester) async {
    await tester.pumpWidget(
      host(
        (context) => ExpressivePopover(
          content: (context) => ExpressiveSplitButton(
            'Share',
            onPressed: () {},
            menu: (context, close) => const Text('Share a copy'),
          ),
          child: const Text('Notes'),
        ),
      ),
    );
    await tester.tap(find.text('Notes'));
    await tester.pumpAndSettle();
    final popover = find.byType(ExpressivePopoverSurface);
    final rest = tester.getRect(popover);
    final route = ModalRoute.of(tester.element(popover))!;
    await tester.tap(find.byType(ExpressiveSplitTrailingButton));
    await tester.pumpAndSettle();
    expect(find.text('Share a copy'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Share a copy'), findsNothing);
    // Neither faded nor scaled back.
    expect(route.isActive, isTrue);
    expect(route.animation!.value, 1);
    expect(tester.getRect(popover), rest);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(popover, findsNothing);
  });

  testWidgets('popovers keep the app theme when the app is not the root', (
    tester,
  ) async {
    // App Preview's host nests every preview inside its own MaterialApp, so
    // the root navigator a popup mounts on sits OUTSIDE the app's host. The
    // popover and the menu must still read the app's tokens there.
    var archived = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: host(
          (context) => Column(
            children: [
              ExpressivePopover(
                content: (context) => const Text('Trip notes'),
                child: const Text('Notes'),
              ),
              const SizedBox(height: 200),
              ExpressiveMenu(
                trigger: ExpressiveMenuTrigger.longPress,
                entries: [
                  ExpressiveMenuItem('Archive', onPressed: () => archived++),
                ],
                child: const Text('Trip'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('Notes'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final surface = tester.widget<ExpressiveSurface>(
      find.descendant(
        of: find.byType(ExpressivePopoverSurface),
        matching: find.byType(ExpressiveSurface),
      ),
    );
    expect(surface.color, bloom.colors.surfaceContainerLow);
    expect(
      DefaultTextStyle.of(tester.element(find.text('Trip notes'))).style.color,
      bloom.colors.onSurface,
    );
    await tester.tapAt(const Offset(1, 1));
    await tester.pumpAndSettle();
    expect(find.text('Trip notes'), findsNothing);

    await tester.longPress(find.text('Trip'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final group = tester.widget<ExpressiveSurface>(
      find.descendant(of: menu, matching: find.byType(ExpressiveSurface)).first,
    );
    expect(group.color, bloom.colors.surfaceContainerLow);
    await tester.tap(itemSurface('Archive'));
    await tester.pumpAndSettle();
    expect(archived, 1);
  });

  testWidgets('popover grows out of its control and collapses back into it', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        (context) => ExpressiveMenu(
          entries: [ExpressiveMenuItem('Archive', onPressed: () {})],
          child: const Text('Trip'),
        ),
      ),
    );
    final trigger = tester.getRect(find.text('Trip'));
    await tester.tap(find.text('Trip'));
    await tester.pumpAndSettle();
    final settled = tester.getRect(menu);

    await tester.tapAt(const Offset(1, 1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Trip'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    // Early in the open the surface is small (it scales from 0.8, never
    // from nothing) and grows out of the point where it meets the control.
    final early = tester.getRect(menu);
    final scale = early.width / settled.width;
    expect(scale, greaterThanOrEqualTo(MenuBehavior.closedScale - 0.01));
    expect(scale, lessThan(0.97));
    expect(early.height / settled.height, closeTo(scale, 0.01));
    final originX = (early.left - scale * settled.left) / (1 - scale);
    final originY = (early.top - scale * settled.top) / (1 - scale);
    expect(originX, greaterThanOrEqualTo(trigger.left - 1));
    expect(originX, lessThanOrEqualTo(trigger.right + 1));
    expect(originY, closeTo(settled.top, 1));

    // Settled: full size, and the spring's overshoot has gone.
    await tester.pumpAndSettle();
    expect(tester.getRect(menu).width, closeTo(settled.width, 0.01));

    // The close shrinks it back toward the control as it fades.
    await tester.tapAt(const Offset(1, 1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 48));
    expect(tester.getRect(menu).width, lessThan(settled.width));
    await tester.pumpAndSettle();
    expect(find.text('Archive'), findsNothing);
  });

  for (final reduce in [false, true]) {
    testWidgets(
      'popover ${reduce ? 'never overshoots under Reduce Motion' : 'overshoots on the expressive spring'}',
      (tester) async {
        // Cody skipped the popover's motion under reduced motion; the kit's
        // policy (DesignMotionPolicy) keeps Expressive's spatial springs and damps
        // them critically instead, so the port asserts no overshoot.
        await tester.pumpWidget(
          host(
            media: MediaQueryData(disableAnimations: reduce),
            (context) => ExpressiveMenu(
              entries: [ExpressiveMenuItem('Archive', onPressed: () {})],
              child: const Text('Trip'),
            ),
          ),
        );
        await tester.tap(find.text('Trip'));
        await tester.pumpAndSettle();
        final settled = tester.getRect(menu).width;
        await tester.tapAt(const Offset(1, 1));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Trip'));
        var widest = 0.0;
        for (var frame = 0; frame < 40; frame++) {
          await tester.pump(const Duration(milliseconds: 16));
          final width = tester.getRect(menu).width;
          if (width > widest) widest = width;
        }
        if (reduce) {
          expect(widest, lessThanOrEqualTo(settled + 0.01));
        } else {
          expect(widest, greaterThan(settled + 0.5));
        }
      },
    );
  }

  // --- Geometry and colour --------------------------------------------------

  testWidgets('groups and items take their geometry from the tokens', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        (context) => ExpressiveMenuSurface(
          groups: [
            ExpressiveMenuGroup(label: 'Trip', [
              ExpressiveMenuItem(
                'Edit',
                icon: ExpressiveSymbols.edit,
                trailingText: 'Ctrl+E',
                onPressed: () {},
              ),
              ExpressiveMenuItem('Duplicate', onPressed: () {}),
              ExpressiveMenuItem('Share', onPressed: () {}),
            ]),
            ExpressiveMenuGroup([
              ExpressiveMenuItem('Delete', onPressed: () {}),
            ]),
          ],
        ),
      ),
    );
    final edit = tester.getRect(itemSurface('Edit'));
    final group = tester.getRect(
      find.descendant(of: menu, matching: find.byType(ExpressiveSurface)).first,
    );
    // 44dp items, 4dp in from the group's sides.
    expect(edit.height, SegmentedMenuTokens.item);
    expect(edit.left - group.left, MenuBehavior.itemInset);
    expect(group.right - edit.right, MenuBehavior.itemInset);
    expect(
      group.width - 2 * MenuBehavior.itemInset,
      inInclusiveRange(112, 280),
    );
    // Each item sits in its 48dp touch target: 4dp apart.
    final duplicate = tester.getRect(itemSurface('Duplicate'));
    expect(duplicate.top - edit.bottom, 4);
    // The icon (20dp) sits 12dp in, the label 8dp after it.
    final icon = tester.getRect(find.byIcon(ExpressiveSymbols.edit));
    expect(icon.left - edit.left, MenuBehavior.itemHorizontalPadding);
    expect(icon.width, SegmentedMenuTokens.itemLeadingIconSize);
    expect(
      tester.getRect(find.text('Edit')).left - icon.right,
      MenuBehavior.itemIconSpacing,
    );
    // The shortcut ends 12dp from the item's end.
    expect(
      edit.right - tester.getRect(find.text('Ctrl+E')).right,
      MenuBehavior.itemHorizontalPadding,
    );
    // Groups: 2dp apart; the first large on top and small below.
    final surfaces = tester
        .widgetList<ExpressiveSurface>(
          find.descendant(of: menu, matching: find.byType(ExpressiveSurface)),
        )
        .toList();
    final first = surfaces.first.shape as ExpressiveCornerBorder;
    final radii = first.radiiOn(group);
    expect(radii.topLeft.x, 16);
    expect(radii.bottomLeft.x, 8);
    final groups = find.descendant(
      of: menu,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is ExpressiveSurface &&
            widget.shadowElevation == ExpressiveElevationLevel.level2,
      ),
    );
    expect(groups, findsNWidgets(2));
    expect(
      tester.getRect(groups.last).top - tester.getRect(groups.first).bottom,
      SegmentedMenuTokens.segmentedGap,
    );
    // Items: medium outside, extra-small between.
    final editShape =
        tester.widget<ExpressiveSurface>(itemSurface('Edit')).shape
            as ExpressiveCornerBorder;
    expect(editShape.radiiOn(edit).topLeft.x, 12);
    expect(editShape.radiiOn(edit).bottomLeft.x, 4);
  });

  testWidgets('a selected item springs to the selected colour and shape', (
    tester,
  ) async {
    var sort = 'Date';
    await tester.pumpWidget(
      host(
        (context) => StatefulBuilder(
          builder: (context, update) => ExpressiveMenuSurface(
            groups: [
              ExpressiveMenuGroup(label: 'Sort by', [
                for (final option in ['Date', 'Name', 'Size'])
                  ExpressiveMenuRadioItem(
                    option,
                    selected: sort == option,
                    onSelected: () => update(() => sort = option),
                  ),
              ]),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    ExpressiveSurface surface(String label) =>
        tester.widget<ExpressiveSurface>(itemSurface(label));
    expect(surface('Date').color, bloom.colors.tertiaryContainer);
    expect(surface('Name').color, bloom.colors.surfaceContainerLow);
    expect(
      tester.getSemantics(find.text('Date')),
      isSemantics(isChecked: true, isInMutuallyExclusiveGroup: true),
    );
    await tester.tap(itemSurface('Name'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    // Mid-spring: on its way, not there.
    expect(surface('Name').color, isNot(bloom.colors.tertiaryContainer));
    await tester.pumpAndSettle();
    expect(surface('Name').color, bloom.colors.tertiaryContainer);
    expect(surface('Date').color, bloom.colors.surfaceContainerLow);
    final rect = tester.getRect(itemSurface('Name'));
    final shape = surface('Name').shape as ExpressiveCornerBorder;
    expect(shape.radiiOn(rect).topLeft.x, 12);
    expect(shape.radiiOn(rect).bottomLeft.x, 12);
  });

  testWidgets('a checkable item toggles in place and keeps the menu open', (
    tester,
  ) async {
    var wrap = false;
    await tester.pumpWidget(
      host(
        (context) => ExpressiveMenu(
          entries: [
            ExpressiveMenuCheckItem(
              'Wrap lines',
              value: wrap,
              onChanged: (value) => wrap = value,
            ),
          ],
          child: const Text('View'),
        ),
      ),
    );
    await tester.tap(find.text('View'));
    await tester.pumpAndSettle();
    expect(find.byIcon(ExpressiveSymbols.check), findsOneWidget);
    final hidden = tester.getSize(find.byIcon(ExpressiveSymbols.check));
    await tester.tap(itemSurface('Wrap lines'));
    await tester.pumpAndSettle();
    expect(wrap, isTrue);
    expect(find.text('Wrap lines'), findsOneWidget);
    expect(
      tester.getSemantics(find.text('Wrap lines')),
      isSemantics(isChecked: true),
    );
    // The check grew in: its clip is as wide as the glyph now.
    final clip = tester.getRect(
      find
          .ancestor(
            of: find.byIcon(ExpressiveSymbols.check),
            matching: find.byType(ClipRect),
          )
          .first,
    );
    expect(clip.width, SegmentedMenuTokens.itemLeadingIconSize);
    expect(hidden.width, SegmentedMenuTokens.itemLeadingIconSize);
  });

  testWidgets('a submenu opens beside its item; a choice closes both', (
    tester,
  ) async {
    var moved = '';
    await tester.pumpWidget(
      host(
        (context) => ExpressiveMenu(
          entries: [
            ExpressiveMenuSubmenu(
              'Move to',
              icon: ExpressiveSymbols.folder,
              groups: [
                ExpressiveMenuGroup([
                  ExpressiveMenuItem('Archive', onPressed: () => moved = 'a'),
                  ExpressiveMenuItem('Trips', onPressed: () => moved = 't'),
                ]),
              ],
            ),
            ExpressiveMenuItem('Delete', onPressed: () {}),
          ],
          child: const Text('Trip'),
        ),
      ),
    );
    await tester.tap(find.text('Trip'));
    await tester.pumpAndSettle();
    await tester.tap(itemSurface('Move to'));
    await tester.pumpAndSettle();
    final item = tester.getRect(itemSurface('Move to'));
    final archive = tester.getRect(itemSurface('Archive'));
    expect(archive.left, greaterThan(item.right));
    await tester.tap(itemSurface('Trips'));
    await tester.pumpAndSettle();
    expect(moved, 't');
    expect(find.text('Move to'), findsNothing);
    expect(find.text('Trips'), findsNothing);
  });

  testWidgets('the menu opens below its anchor, start edges aligned', (
    tester,
  ) async {
    for (final direction in TextDirection.values) {
      await tester.pumpWidget(
        host(
          direction: direction,
          (context) => ExpressiveMenu(
            entries: [ExpressiveMenuItem('Archive', onPressed: () {})],
            child: const SizedBox(width: 160, height: 40),
          ),
        ),
      );
      final anchor = tester.getRect(find.byType(ExpressiveMenu));
      await tester.tap(find.byType(ExpressiveMenu));
      await tester.pumpAndSettle();
      final placed = tester.getRect(menu);
      expect(placed.top, anchor.bottom);
      if (direction == TextDirection.ltr) {
        expect(placed.left, anchor.left);
      } else {
        expect(placed.right, anchor.right);
      }
      await tester.tapAt(const Offset(1, 1));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('a builder anchor opens and closes the menu by controller', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        (context) => ExpressiveMenu(
          label: 'More options',
          entries: [ExpressiveMenuItem('Archive', onPressed: () {})],
          builder: (context, menu) => GestureDetector(
            onTap: menu.toggle,
            child: Text(menu.isOpen ? 'Open' : 'Closed'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Closed'));
    await tester.pumpAndSettle();
    expect(find.text('Archive'), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Archive'), findsNothing);
    expect(find.text('Closed'), findsOneWidget);
  });

  testWidgets('a vibrant menu is a hero: it needs an ExpressiveHeroMoment', (
    tester,
  ) async {
    final groups = [
      ExpressiveMenuGroup([ExpressiveMenuItem('Archive', onPressed: () {})]),
    ];
    await tester.pumpWidget(
      host((context) => ExpressiveMenuSurface(vibrant: true, groups: groups)),
    );
    expect(tester.takeException(), isFlutterError);
    await tester.pumpWidget(
      host(
        (context) => ExpressiveHeroMoment(
          child: ExpressiveMenuSurface(vibrant: true, groups: groups),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    final group = tester.widget<ExpressiveSurface>(
      find.descendant(of: menu, matching: find.byType(ExpressiveSurface)).first,
    );
    expect(group.color, bloom.colors.tertiaryContainer);
  });

  testWidgets('menus fit at text scale 1.3 in both directions', (tester) async {
    for (final direction in TextDirection.values) {
      await tester.pumpWidget(
        host(
          scale: 1.3,
          direction: direction,
          (context) => ExpressiveMenuSurface(
            groups: [
              ExpressiveMenuGroup(label: 'Arrange', [
                ExpressiveMenuItem(
                  'Move to another collection',
                  icon: ExpressiveSymbols.folder,
                  supportingText: 'Keeps its notes and photos',
                  trailingText: 'Ctrl+M',
                  onPressed: () {},
                ),
                const ExpressiveMenuDivider(),
                ExpressiveMenuCheckItem(
                  'Pinned',
                  value: true,
                  onChanged: (_) {},
                ),
              ]),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  // --- The exposed-dropdown hooks a select and a combobox compose -----------

  testWidgets('matchAnchorWidth sizes the menu to its anchor; maxHeight '
      'scrolls it', (tester) async {
    await tester.pumpWidget(
      host(
        (context) => ExpressiveMenu(
          matchAnchorWidth: true,
          maxHeight: 150,
          entries: [
            for (var i = 0; i < 8; i++)
              ExpressiveMenuItem('Option $i', onPressed: () {}),
          ],
          child: const SizedBox(width: 300, height: 56),
        ),
      ),
    );
    final anchor = tester.getRect(find.byType(ExpressiveMenu));
    await tester.tap(find.byType(ExpressiveMenu));
    await tester.pumpAndSettle();
    final scroller = tester.getRect(
      find.ancestor(of: menu, matching: find.byType(SingleChildScrollView)),
    );
    expect(scroller.width, anchor.width);
    expect(scroller.left, anchor.left);
    expect(scroller.height, 150);
    expect(find.text('Option 7').hitTestable(), findsNothing);
  });

  testWidgets('a non-modal menu leaves focus and typing on its anchor', (
    tester,
  ) async {
    final field = TextEditingController();
    final focus = FocusNode();
    final menuController = ExpressiveMenuController();
    String? chosen;
    await tester.pumpWidget(
      host(
        (context) => Column(
          children: [
            ExpressiveMenu(
              modal: false,
              matchAnchorWidth: true,
              controller: menuController,
              entries: [
                ExpressiveMenuItem(
                  'Lisbon',
                  onPressed: () => chosen = 'Lisbon',
                ),
                ExpressiveMenuItem('Oslo', onPressed: () => chosen = 'Oslo'),
              ],
              builder: (context, menu) => SizedBox(
                width: 280,
                child: EditableText(
                  controller: field,
                  focusNode: focus,
                  style: const TextStyle(fontSize: 16),
                  cursorColor: const Color(0xFF000000),
                  backgroundCursorColor: const Color(0xFF000000),
                  onChanged: (_) => menu.open(),
                ),
              ),
            ),
            const SizedBox(key: ValueKey('outside'), width: 280, height: 200),
          ],
        ),
      ),
    );
    await tester.showKeyboard(find.byType(EditableText));
    await tester.enterText(find.byType(EditableText), 'L');
    await tester.pumpAndSettle();
    expect(menuController.isOpen, isTrue);
    expect(find.text('Lisbon'), findsOneWidget);
    expect(find.byType(ModalBarrier), findsOneWidget); // the page's own only
    expect(focus.hasPrimaryFocus, isTrue);
    expect(
      tester.getSize(find.byType(ExpressiveMenuSurface)).width,
      tester.getSize(find.byType(EditableText)).width,
    );
    // Typing goes on; a tap on the anchor keeps the menu.
    await tester.enterText(find.byType(EditableText), 'Li');
    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();
    expect(field.text, 'Li');
    expect(menuController.isOpen, isTrue);
    // The keyboard moves into the items.
    menuController.focusFirstItem();
    await tester.pump();
    expect(focus.hasPrimaryFocus, isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(chosen, 'Oslo');
    expect(menuController.isOpen, isFalse);
    expect(find.text('Lisbon'), findsNothing);
    // A tap outside closes it.
    await tester.enterText(find.byType(EditableText), 'O');
    await tester.pumpAndSettle();
    expect(menuController.isOpen, isTrue);
    await tester.tapAt(
      tester.getBottomRight(find.byKey(const ValueKey('outside'))) -
          const Offset(4, 4),
    );
    await tester.pumpAndSettle();
    expect(menuController.isOpen, isFalse);
    expect(chosen, 'Oslo');
    expect(find.text('Oslo'), findsNothing);
    focus.dispose();
    field.dispose();
    menuController.dispose();
  });
}
