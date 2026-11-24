/// A list opened from a field is the field's width, wider only for its
/// widest item, from its first frame; a popup held open over its route (a
/// combobox's suggestions, a split button's menu) closes under a route
/// pushed over it, on its navigator or another; a context menu opened by a
/// long press says no collapsed state.
library;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/behavior.g.dart';

final ExpressiveThemeData bloom = ExpressiveThemeData.preset(
  'bloom',
  Brightness.light,
);

/// Expressive's host round a page holding [child] at its start, 24dp in.
Widget host(
  Widget child, {
  TextDirection direction = TextDirection.ltr,
  GlobalKey<NavigatorState>? inner,
}) {
  Widget page(BuildContext context) => Directionality(
    textDirection: direction,
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Align(alignment: AlignmentDirectional.topStart, child: child),
    ),
  );
  return MaterialApp(
    builder: (context, app) =>
        ExpressiveHost(theme: bloom, brightness: Brightness.light, child: app!),
    home: inner == null
        ? Builder(builder: page)
        // A page in a nested navigator, as a shell's content is.
        : Navigator(
            key: inner,
            onGenerateRoute: (settings) =>
                MaterialPageRoute<void>(settings: settings, builder: page),
          ),
  );
}

/// The list's box: the menu's surface, its rows scrolling inside it, as
/// laid out.
Finder get list => find.byType(ExpressiveMenuSurface);

/// Pushes an alert on the root navigator, as `showDialog` does: a route
/// that is not opaque, its one control taking the focus.
Future<(Route<void>, FocusNode)> pushAlert(
  WidgetTester tester,
  Finder over,
) async {
  final ok = FocusNode(debugLabel: 'alert');
  addTearDown(ok.dispose);
  final alert = PageRouteBuilder<void>(
    opaque: false,
    pageBuilder: (context, _, _) => Center(
      child: Focus(
        focusNode: ok,
        autofocus: true,
        child: const SizedBox(width: 120, height: 48),
      ),
    ),
  );
  Navigator.of(tester.element(over), rootNavigator: true).push(alert);
  await tester.pumpAndSettle();
  return (alert, ok);
}

const List<ExpressiveSelectOption<String>> sizes = [
  ExpressiveSelectOption('s', 'Small'),
  ExpressiveSelectOption('m', 'Medium'),
  ExpressiveSelectOption('l', 'Large'),
];

void main() {
  group('a list from a field', () {
    for (final direction in TextDirection.values) {
      testWidgets('is the field\'s width with short items, from its first '
          'frame, on its leading edge (${direction.name})', (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          host(
            SizedBox(
              width: 342,
              child: ExpressiveSelect<String>(
                options: sizes,
                value: 'm',
                onChanged: (_) {},
                labelText: 'Size',
              ),
            ),
            direction: direction,
          ),
        );
        final anchor = find.descendant(
          of: find.byType(ExpressiveSelect<String>),
          matching: find.byType(ExpressiveMenu),
        );
        final field = tester.getRect(anchor);
        await tester.tap(anchor);
        await tester.pump();
        await tester.pump();
        // Its first frame on screen, still scaling in: laid out at its width.
        expect(list, findsOneWidget);
        expect(tester.getSize(list).width, field.width);
        await tester.pumpAndSettle();
        final open = tester.getRect(list);
        expect(open.width, field.width);
        expect(
          direction == TextDirection.ltr ? open.left : open.right,
          direction == TextDirection.ltr ? field.left : field.right,
        );
      });

      testWidgets('grows past a narrow field only as far as its widest item '
          'needs (${direction.name})', (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          host(
            ExpressiveMenu(
              matchAnchorWidth: true,
              entries: [
                ExpressiveMenuItem('A', onPressed: () {}),
                ExpressiveMenuItem('Photography', onPressed: () {}),
              ],
              child: const SizedBox(width: 120, height: 56),
            ),
            direction: direction,
          ),
        );
        final field = tester.getRect(find.byType(ExpressiveMenu));
        await tester.tap(find.byType(ExpressiveMenu));
        await tester.pump();
        await tester.pump();
        final first = tester.getSize(list).width;
        await tester.pumpAndSettle();
        final open = tester.getRect(list);
        // The width it opened at is the width it keeps.
        expect(open.width, first);
        expect(open.width, greaterThan(field.width));
        // The widest item's words fit on one line: no wider than an item
        // may be (280dp, with the group's sides), never the window's width.
        final words = tester.getSize(find.text('Photography'));
        expect(words.height, lessThan(30));
        expect(open.width, lessThan(MenuBehavior.itemMaxWidth));
        expect(
          direction == TextDirection.ltr ? open.left : open.right,
          direction == TextDirection.ltr ? field.left : field.right,
        );
      });
    }

    testWidgets('is never wider than the window\'s margins allow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, app) => ExpressiveHost(
            theme: bloom,
            brightness: Brightness.light,
            child: app!,
          ),
          home: Align(
            alignment: Alignment.topCenter,
            child: ExpressiveMenu(
              matchAnchorWidth: true,
              entries: [ExpressiveMenuItem('Small', onPressed: () {})],
              child: const SizedBox(width: 390, height: 56),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(ExpressiveMenu));
      await tester.pumpAndSettle();
      final open = tester.getRect(list);
      expect(open.width, 390 - 2 * MenuBehavior.horizontalMargin);
      expect(open.left, MenuBehavior.horizontalMargin);
    });
  });

  group('a popup held open over its route', () {
    Future<void> typeIntoCombobox(WidgetTester tester) async {
      await tester.showKeyboard(find.byType(EditableText));
      await tester.enterText(find.byType(EditableText), 'S');
      await tester.pumpAndSettle();
    }

    testWidgets('a combobox\'s suggestions close under an alert pushed over '
        'them, leave it the focus, and stay closed once it is gone', (
      tester,
    ) async {
      final menu = ExpressiveMenuController();
      addTearDown(menu.dispose);
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 320,
            child: ExpressiveCombobox<String>(
              options: sizes,
              labelText: 'Size',
              menuController: menu,
            ),
          ),
        ),
      );
      await typeIntoCombobox(tester);
      expect(menu.isOpen, isTrue);
      expect(find.byType(ExpressiveMenuSurface), findsOneWidget);

      final (alert, ok) = await pushAlert(tester, find.byType(EditableText));
      expect(menu.isOpen, isFalse);
      expect(find.byType(ExpressiveMenuSurface), findsNothing);
      expect(ok.hasPrimaryFocus, isTrue);

      Navigator.of(tester.element(find.byType(EditableText)))
          .removeRoute(alert);
      await tester.pumpAndSettle();
      expect(menu.isOpen, isFalse);
      expect(find.byType(ExpressiveMenuSurface), findsNothing);

      // Typing opens them again.
      await tester.enterText(find.byType(EditableText), 'Sm');
      await tester.pumpAndSettle();
      expect(menu.isOpen, isTrue);
    });

    testWidgets('they close under an alert on the root navigator over a page '
        'in a nested one, which takes the focus from the page', (tester) async {
      final menu = ExpressiveMenuController();
      addTearDown(menu.dispose);
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 320,
            child: ExpressiveCombobox<String>(
              options: sizes,
              labelText: 'Size',
              menuController: menu,
            ),
          ),
          inner: GlobalKey<NavigatorState>(),
        ),
      );
      await typeIntoCombobox(tester);
      expect(menu.isOpen, isTrue);
      // The page's route is its navigator's top one throughout.
      final page = ModalRoute.of(tester.element(find.byType(EditableText)))!;

      final (alert, ok) = await pushAlert(tester, find.byType(EditableText));
      expect(page.isCurrent, isTrue);
      expect(menu.isOpen, isFalse);
      expect(find.byType(ExpressiveMenuSurface), findsNothing);
      expect(ok.hasPrimaryFocus, isTrue);

      alert.navigator!.removeRoute(alert);
      await tester.pumpAndSettle();
      expect(menu.isOpen, isFalse);
    });

    testWidgets('focus moving into them, within the page, keeps them open', (
      tester,
    ) async {
      final menu = ExpressiveMenuController();
      addTearDown(menu.dispose);
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 320,
            child: ExpressiveCombobox<String>(
              options: sizes,
              labelText: 'Size',
              menuController: menu,
            ),
          ),
        ),
      );
      await typeIntoCombobox(tester);
      expect(menu.isOpen, isTrue);
      menu.focusFirstItem();
      await tester.pumpAndSettle();
      expect(
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<ExpressiveMenuSurface>(),
        isNotNull,
      );
      expect(menu.isOpen, isTrue);
    });

    testWidgets('a split button\'s menu closes under an alert pushed over it', (
      tester,
    ) async {
      final changes = <bool>[];
      await tester.pumpWidget(
        host(
          ExpressiveSplitButton(
            'Send',
            onPressed: () {},
            onMenuOpenChanged: changes.add,
            menu: (context, close) => const Text('Schedule send'),
          ),
        ),
      );
      await tester.tap(find.byType(ExpressiveSplitTrailingButton));
      await tester.pumpAndSettle();
      expect(find.text('Schedule send'), findsOneWidget);

      final (alert, ok) = await pushAlert(
        tester,
        find.byType(ExpressiveSplitButton),
      );
      expect(find.text('Schedule send'), findsNothing);
      expect(changes, [true, false]);
      expect(ok.hasPrimaryFocus, isTrue);

      alert.navigator!.removeRoute(alert);
      await tester.pumpAndSettle();
      expect(find.text('Schedule send'), findsNothing);
    });
  });

  testWidgets('a context menu says a long press shows it, and no collapsed '
      'state: a tap opens nothing', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        ExpressiveMenu(
          trigger: ExpressiveMenuTrigger.longPress,
          label: 'Message',
          entries: [ExpressiveMenuItem('Reply', onPressed: () {})],
          // A message's bubble: it takes a press itself.
          child: const ColoredBox(
            color: Color(0xFFE8DEF8),
            child: SizedBox(width: 200, height: 56),
          ),
        ),
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Message')),
      isSemantics(
        label: 'Message',
        hasLongPressAction: true,
        onLongPressHint: 'Show menu',
        hasTapAction: false,
        hasExpandedState: false,
      ),
    );

    await tester.tap(find.bySemanticsLabel('Message'));
    await tester.pumpAndSettle();
    expect(find.text('Reply'), findsNothing);
    await tester.longPress(find.bySemanticsLabel('Message'));
    await tester.pumpAndSettle();
    expect(find.text('Reply'), findsOneWidget);
    handle.dispose();
  });
}
