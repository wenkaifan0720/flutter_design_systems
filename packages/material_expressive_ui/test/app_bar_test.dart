/// The app bars family: the small, medium and large flexible bars
/// (Compose's heights, `TopAppBarLayout`'s placement, the collapse by
/// height offset, the colour fill on scroll), the overflow menu, the
/// derived exit, the search app bar, the search bar and its view (open,
/// type, results, collapse, predictive back geometry, a menu held open in
/// it taking the back first) and the search field — with Cody's search
/// clear/cancel tests ported (F14).
library;

import 'package:material_ui/material_ui.dart' show InkResponse, MaterialApp;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/behavior.g.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/search_bar_tokens.g.dart';

import 'support/pressable.dart';

final ExpressiveThemeData _theme = ExpressiveThemeData.preset(
  'baseline',
  Brightness.light,
);

ExpressiveColorScheme get _c => _theme.colors;

/// [child] at the top of an Expressive app, [width] wide.
Widget _app(Widget child, {double width = 412}) => MaterialApp(
  builder: (context, app) =>
      ExpressiveHost(light: _theme, brightness: Brightness.light, child: app!),
  home: Align(
    alignment: Alignment.topLeft,
    child: SizedBox(width: width, child: child),
  ),
);

/// The colour the bar's container paints.
Color _containerColor(WidgetTester tester) => tester
    .widget<ExpressiveSurface>(
      find
          .descendant(
            of: find.byType(ExpressiveAppBar),
            matching: find.byType(ExpressiveSurface),
          )
          .first,
    )
    .color;

void _noop() {}

void main() {
  testWidgets(
    'app-bar style geometry agrees with its measured height and scroll states',
    (tester) async {
      const rest = Color(0xff123456);
      const scrolled = Color(0xff654321);
      final style = ExpressiveComponentThemeData(
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.scrolledUnder) ? scrolled : rest,
        ),
        shape: const WidgetStatePropertyAll(
          BeveledRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
        padding: const WidgetStatePropertyAll(EdgeInsets.all(12)),
        minimumSize: const WidgetStatePropertyAll(Size(0, 100)),
        textStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 24)),
      );
      final bar = ExpressiveAppBar(title: 'Inbox', style: style);
      await tester.pumpWidget(_app(bar));
      await tester.pumpAndSettle();
      expect(_containerColor(tester), rest);
      expect(
        tester.getSize(find.byType(ExpressiveAppBar)).height,
        bar.collapsedHeightOf(tester.element(find.byType(ExpressiveAppBar))),
      );
      expect(tester.getSize(find.byType(ExpressiveAppBar)).height, 100);
      await tester.pumpWidget(
        _app(
          ExpressiveAppBar(
            title: 'Inbox',
            style: style,
            scroll: const ExpressiveAppBarScroll(contentOffset: -120),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_containerColor(tester), scrolled);
    },
  );

  group('ExpressiveAppBar small', () {
    testWidgets('is 64dp: title 16dp in, or after the navigation icon', (
      tester,
    ) async {
      await tester.pumpWidget(_app(const ExpressiveAppBar(title: 'Inbox')));
      expect(tester.getSize(find.byType(ExpressiveAppBar)).height, 64);
      // TopAppBarTitleInset (12) + the title box's 4dp.
      expect(tester.getTopLeft(find.text('Inbox')).dx, 16);

      await tester.pumpWidget(
        _app(
          const ExpressiveAppBar(
            title: 'Inbox',
            leading: ExpressiveIconButton(
              ExpressiveSymbols.menu,
              onPressed: _noop,
              semanticLabel: 'Menu',
            ),
            actions: <Widget>[
              ExpressiveAppBarAction(
                ExpressiveSymbols.search,
                label: 'Search',
                onPressed: _noop,
              ),
            ],
          ),
        ),
      );
      // The navigation box: 4dp + the 48dp touch target; the title 4dp
      // after it.
      expect(tester.getTopLeft(find.text('Inbox')).dx, 4 + 48 + 4);
      final search = tester.getRect(find.bySemanticsLabel('Search'));
      expect(412 - search.right, closeTo(4, 0.01)); // the 48dp target
      final menu = tester.getRect(find.bySemanticsLabel('Menu'));
      expect(menu.left, closeTo(4, 0.01));
      expect(menu.center.dy, 32);
    });

    testWidgets('centres its title on the whole width, clear of the ends', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(const ExpressiveAppBar(title: 'Photos', centered: true)),
      );
      expect(tester.getCenter(find.text('Photos')).dx, closeTo(206, 0.01));
    });

    testWidgets('a long title stays on one line inside its slot (Cody: '
        'compact top bar title reads whole at phone width)', (tester) async {
      // Material ellipsizes where Cody scales down: the port holds the
      // title to one line inside the space between the ends.
      const title = 'Recorded just now · Morning window · Fasting glucose';
      await tester.pumpWidget(
        _app(
          const ExpressiveAppBar(
            title: title,
            actions: <Widget>[
              ExpressiveAppBarAction(
                ExpressiveSymbols.share,
                label: 'Share',
                onPressed: _noop,
              ),
            ],
          ),
          width: 390,
        ),
      );
      final rect = tester.getRect(find.text(title));
      expect(rect.height, lessThan(40));
      expect(rect.right, lessThanOrEqualTo(390 - 4 - 48 - 4));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a textual leading action gets one line (Cody: compact top '
        'bar gives a textual leading action one line)', (tester) async {
      await tester.pumpWidget(
        _app(
          ExpressiveAppBar(
            title: 'New message',
            leading: GestureDetector(onTap: () {}, child: const Text('Cancel')),
          ),
        ),
      );
      final size = tester.getSize(find.text('Cancel'));
      expect(size.width, greaterThan(40));
      expect(size.height, lessThan(30));
      expect(tester.takeException(), isNull);
    });

    testWidgets('fills with surfaceContainer once content passes under it', (
      tester,
    ) async {
      await tester.pumpWidget(_app(const ExpressiveAppBar(title: 'Inbox')));
      expect(_containerColor(tester), _c.surface);
      await tester.pumpWidget(
        _app(
          const ExpressiveAppBar(
            title: 'Inbox',
            scroll: ExpressiveAppBarScroll(contentOffset: -8),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_containerColor(tester), _c.surfaceContainer);
    });

    testWidgets('folds actions past two into the overflow menu', (
      tester,
    ) async {
      var printed = 0;
      await tester.pumpWidget(
        _app(
          ExpressiveAppBar(
            title: 'Review',
            actions: <Widget>[
              const ExpressiveAppBarAction(
                ExpressiveSymbols.edit,
                label: 'Edit',
                onPressed: _noop,
              ),
              const ExpressiveAppBarAction(
                ExpressiveSymbols.share,
                label: 'Share',
                onPressed: _noop,
              ),
              ExpressiveAppBarAction(
                ExpressiveSymbols.print,
                label: 'Print',
                onPressed: () => printed++,
              ),
            ],
          ),
        ),
      );
      expect(find.byType(ExpressiveIconButton), findsNWidgets(3));
      expect(find.text('Print'), findsNothing);
      await tester.tap(pressableOf(find.byIcon(ExpressiveSymbols.moreVert)));
      await tester.pumpAndSettle();
      await tester.tap(pressableOf(find.text('Print')));
      await tester.pumpAndSettle();
      expect(printed, 1);
    });
  });

  group('ExpressiveAppBar flexible', () {
    testWidgets('Compose\'s expanded heights, with and without a subtitle', (
      tester,
    ) async {
      const cases = <(ExpressiveAppBarSize, String?, double)>[
        (ExpressiveAppBarSize.medium, null, 112),
        (ExpressiveAppBarSize.medium, 'Week 21', 136),
        (ExpressiveAppBarSize.large, null, 120),
        (ExpressiveAppBarSize.large, 'Week 21', 152),
      ];
      for (final (size, subtitle, height) in cases) {
        await tester.pumpWidget(
          _app(
            ExpressiveAppBar(title: 'Journal', subtitle: subtitle, size: size),
          ),
        );
        expect(
          tester.getSize(find.byType(ExpressiveAppBar)).height,
          height,
          reason: '$size $subtitle',
        );
      }
    });

    testWidgets('collapses by its height offset to the 64dp row, filling', (
      tester,
    ) async {
      Future<void> pump(double offset) => tester.pumpWidget(
        _app(
          ExpressiveAppBar(
            title: 'Journal',
            large: true,
            scroll: ExpressiveAppBarScroll(heightOffset: offset),
          ),
        ),
      );
      await pump(-28);
      expect(tester.getSize(find.byType(ExpressiveAppBar)).height, 92);
      await pump(-56);
      expect(tester.getSize(find.byType(ExpressiveAppBar)).height, 64);
      expect(_containerColor(tester), _c.surfaceContainer);
      await pump(-200);
      expect(tester.getSize(find.byType(ExpressiveAppBar)).height, 64);
      await pump(0);
      expect(_containerColor(tester), _c.surface);
    });

    testWidgets('announces one title at a time', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(const ExpressiveAppBar(title: 'Journal', large: true)),
      );
      expect(find.bySemanticsLabel('Journal'), findsOneWidget);
      semantics.dispose();
    });
  });

  group('autoLeading', () {
    testWidgets('the back arrow on a pushed page, nothing on a root', (
      tester,
    ) async {
      await tester.pumpWidget(_app(const ExpressiveAppBar(title: 'Home')));
      expect(find.byType(ExpressiveIconButton), findsNothing);
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.push(
        PageRouteBuilder<void>(
          pageBuilder: (context, _, _) =>
              const ExpressiveAppBar(title: 'Detail'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(ExpressiveSymbols.arrowBack), findsOneWidget);
      await tester.tap(pressableOf(find.byIcon(ExpressiveSymbols.arrowBack)));
      await tester.pumpAndSettle();
      expect(find.text('Detail'), findsNothing);
    });

    testWidgets('close in a full-screen dialog', (tester) async {
      await tester.pumpWidget(_app(const SizedBox()));
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.push(
        ExpressiveSheetPage<void>(
          drawer: true,
          child: const ExpressiveAppBar(title: 'New entry'),
        ).createRoute(tester.element(find.byType(SizedBox).first)),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(ExpressiveSymbols.close), findsOneWidget);
    });
  });

  group('search', () {
    testWidgets('the search app bar: 64dp around a 56dp bar', (tester) async {
      await tester.pumpWidget(
        _app(
          const ExpressiveAppBar.search(
            leading: ExpressiveIconButton(
              ExpressiveSymbols.menu,
              onPressed: _noop,
              semanticLabel: 'Menu',
            ),
            search: ExpressiveSearchBar(hintText: 'Search mail'),
          ),
        ),
      );
      expect(tester.getSize(find.byType(ExpressiveAppBar)).height, 64);
      final bar = tester.getRect(find.byType(ExpressiveSearchBar));
      expect(bar.height, 56);
      expect(bar.top, 4);
      // 412 - (4 + 48) nav - 2 × 8 around the bar - 4 at the end.
      expect(bar.width, 412 - 52 - 16 - 4);
    });

    testWidgets('opens the view, searches live, and collapses on back', (
      tester,
    ) async {
      final queries = <String>[];
      await tester.pumpWidget(
        _app(
          ExpressiveSearchBar(
            hintText: 'Search places',
            onChanged: queries.add,
            filters: const <Widget>[Text('Open now')],
            results: (context, query) => Text('results for "$query"'),
          ),
        ),
      );
      await tester.tap(find.byType(ExpressiveSearchBar));
      await tester.pumpAndSettle();
      expect(find.text('Open now'), findsOneWidget);
      expect(find.text('results for ""'), findsOneWidget);
      await tester.enterText(find.byType(EditableText), 'bel');
      await tester.pump();
      expect(find.text('results for "bel"'), findsOneWidget);
      expect(queries, <String>['bel']);
      // The view fills the screen, square-cornered.
      expect(
        tester.getSize(find.byType(ExpressiveSearchField)).width,
        tester.view.physicalSize.width / tester.view.devicePixelRatio,
      );
      await tester.tap(find.bySemanticsLabel('Cancel search'));
      await tester.pumpAndSettle();
      expect(find.text('Open now'), findsNothing);
      expect(find.byType(EditableText), findsNothing);
    });

    testWidgets('expands on the slow spatial spring, collapses on the '
        'default one', (tester) async {
      await tester.pumpWidget(_app(const ExpressiveSearchBar()));
      final motion = ExpressiveMotion.of(
        tester.element(find.byType(ExpressiveSearchBar)),
      );
      await tester.tap(find.byType(ExpressiveSearchBar));
      await tester.pumpAndSettle();
      final route = ModalRoute.of(tester.element(find.byType(EditableText)))!;
      final expand = motion.spring(SearchBarBehavior.expandMotion);
      final collapse = motion.spring(SearchBarBehavior.collapseMotion);
      expect(SearchBarBehavior.expandMotion, ExpressiveMotionKey.slowSpatial);
      expect(
        SearchBarBehavior.collapseMotion,
        ExpressiveMotionKey.defaultSpatial,
      );
      expect(route.transitionDuration, expressiveSettleTime(expand));
      expect(route.reverseTransitionDuration, expressiveSettleTime(collapse));
      expect(route.transitionDuration, isNot(route.reverseTransitionDuration));
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
    });

    testWidgets('the system back collapses the view', (tester) async {
      await tester.pumpWidget(_app(const ExpressiveSearchBar()));
      await tester.tap(find.byType(ExpressiveSearchBar));
      await tester.pumpAndSettle();
      expect(find.byType(EditableText), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(EditableText), findsNothing);
    });

    testWidgets('a menu open in the view takes the first back; the view '
        'stays open and previews no collapse', (tester) async {
      Future<void> backGesture(String method, [double? progress]) async {
        await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
          'flutter/backgesture',
          const StandardMethodCodec().encodeMethodCall(
            MethodCall(
              method,
              progress == null
                  ? null
                  : <String, Object?>{
                      'touchOffset': <double>[4 + progress * 200, 400],
                      'progress': progress,
                      'swipeEdge': 0,
                    },
            ),
          ),
          (_) {},
        );
        await tester.pump();
      }

      await tester.pumpWidget(
        _app(
          ExpressiveSearchBar(
            results: (context, query) => Center(
              child: ExpressiveSplitButton(
                'Filter',
                onPressed: _noop,
                menu: (context, close) => const Text('Save this search'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(ExpressiveSearchBar));
      await tester.pumpAndSettle();
      final field = find.byType(ExpressiveSearchField);
      final view = tester.getRect(field);
      final route = ModalRoute.of(tester.element(find.byType(EditableText)))!;
      await tester.tap(find.byType(ExpressiveSplitTrailingButton));
      await tester.pumpAndSettle();
      expect(find.text('Save this search'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Save this search'), findsNothing);
      expect(find.byType(EditableText), findsOneWidget);
      expect(route.animation!.value, 1);
      expect(tester.getRect(field), view);

      // Android predictive back: no preview while the menu is open.
      await tester.tap(find.byType(ExpressiveSplitTrailingButton));
      await tester.pumpAndSettle();
      await backGesture('startBackGesture', 0);
      await backGesture('updateBackGestureProgress', 0.5);
      expect(tester.getRect(field), view);
      await backGesture('commitBackGesture');
      await tester.pumpAndSettle();
      expect(find.text('Save this search'), findsNothing);
      expect(find.byType(EditableText), findsOneWidget);
      expect(tester.getRect(field), view);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(EditableText), findsNothing);
    });

    testWidgets('the page rebuilding under the view, open or collapsing, '
        'reaches its results', (tester) async {
      var count = 0;
      late StateSetter rebuild;
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return ExpressiveSearchBar(
                results: (context, query) => Text('Results $count'),
              );
            },
          ),
        ),
      );
      await tester.tap(find.byType(ExpressiveSearchBar));
      await tester.pumpAndSettle();
      expect(find.text('Results 0'), findsOneWidget);

      rebuild(() => count = 1);
      await tester.pump();
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Results 1'), findsOneWidget);

      // Popped, still collapsing: the view is mounted and hears it too.
      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      rebuild(() => count = 2);
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(find.byType(EditableText), findsNothing);
    });

    group('the collapsed bar\'s trailing icons and avatar', () {
      const avatar = Key('avatar');

      /// A bar with a trailing icon and an avatar, as Margin's and
      /// Earshot's home bars hold them.
      Widget bar({
        VoidCallback? onSort,
        VoidCallback? onAccount,
        VoidCallback? onOpen,
      }) => _app(
        ExpressiveSearchBar(
          hintText: 'Search notes',
          trailing: <Widget>[
            ExpressiveIconButton(
              ExpressiveSymbols.sort,
              onPressed: onSort ?? _noop,
              semanticLabel: 'View and sort',
            ),
          ],
          avatar: const ColoredBox(
            key: avatar,
            color: Color(0xFF6750A4),
            child: SizedBox.square(dimension: 30),
          ),
          avatarLabel: 'Account',
          onAvatarTap: onAccount ?? _noop,
          onOpen: onOpen,
        ),
      );

      /// The bar's own ink: the last in the bar, after its content's.
      InkResponse barInk(WidgetTester tester) => tester.widget<InkResponse>(
        find
            .descendant(
              of: find.byType(ExpressiveSearchBar),
              matching: find.byType(InkResponse),
            )
            .last,
      );

      bool barPressed(WidgetTester tester) =>
          barInk(tester).statesController!.value.contains(WidgetState.pressed);

      testWidgets('take their own taps; the rest of the bar opens search', (
        tester,
      ) async {
        var sorts = 0;
        var accounts = 0;
        var opens = 0;
        await tester.pumpWidget(
          bar(
            onSort: () => sorts++,
            onAccount: () => accounts++,
            onOpen: () => opens++,
          ),
        );
        await tester.tap(find.byType(ExpressiveIconButton));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(avatar));
        await tester.pumpAndSettle();
        expect((sorts, accounts, opens), (1, 1, 0));
        expect(find.byType(EditableText), findsNothing);

        await tester.tapAt(tester.getCenter(find.text('Search notes')));
        await tester.pumpAndSettle();
        expect((sorts, accounts, opens), (1, 1, 1));
        expect(find.byType(EditableText), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
      });

      testWidgets('held, press only themselves; the bar presses (its ripple) '
          'everywhere else', (tester) async {
        await tester.pumpWidget(bar());
        for (final (at, pressed) in <(Finder, bool)>[
          (find.byType(ExpressiveIconButton), false),
          (find.byKey(avatar), false),
          (find.text('Search notes'), true),
          (find.byType(ExpressiveIcon).first, true),
        ]) {
          final gesture = await tester.startGesture(tester.getCenter(at));
          await tester.pump(const Duration(milliseconds: 500));
          expect(barPressed(tester), pressed, reason: '$at');
          await gesture.cancel();
          await tester.pumpAndSettle();
        }
        // The ripple is the pressable's own, in the bar's input text colour.
        expect(
          barInk(tester).splashColor,
          _c.role(SearchBarTokens.inputTextColor).withValues(alpha: 0.1),
        );
      });

      testWidgets('are a button each, beside the bar\'s own', (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(bar());
        final barNode = tester.getSemantics(find.text('Search notes'));
        expect(
          barNode,
          isSemantics(isButton: true, isEnabled: true, hasTapAction: true),
        );
        // What the bar announces: its own label, none of its controls'.
        final said = barNode.getSemanticsData().label;
        expect(said, contains('Search notes'));
        expect(said, isNot(contains('View and sort')));
        expect(said, isNot(contains('Account')));
        for (final (control, label) in <(Finder, String)>[
          (find.byType(ExpressiveIconButton), 'View and sort'),
          (find.byKey(avatar), 'Account'),
        ]) {
          final node = tester.getSemantics(control);
          expect(node.isMergedIntoParent, isFalse, reason: label);
          expect(
            node,
            isSemantics(
              label: label,
              isButton: true,
              isEnabled: true,
              hasTapAction: true,
            ),
          );
        }
        handle.dispose();
      });
    });

    test('the view grows from the collapsed bar to the screen', () {
      const screen = Size(412, 915);
      const bar = Rect.fromLTWH(26, 4, 360, 56);
      final collapsed = expressiveSearchViewGeometry(
        screen: screen,
        collapsed: bar,
        progress: 0,
      );
      expect(collapsed.surface, bar);
      expect(collapsed.field, bar);
      expect(collapsed.corner, 28);
      final expanded = expressiveSearchViewGeometry(
        screen: screen,
        collapsed: bar,
        progress: 1,
        topInset: 24,
      );
      expect(expanded.surface, Offset.zero & screen);
      expect(expanded.corner, 0);
      // Under the status bar and SearchBarVerticalPadding.
      expect(expanded.field, const Rect.fromLTWH(0, 32, 412, 56));
      expect(expanded.content.top, 32 + 56 + 8);
      // Contained: the field keeps 8dp either side and 4dp above.
      final contained = expressiveSearchViewGeometry(
        screen: screen,
        collapsed: bar,
        progress: 1,
        topInset: 24,
        contained: true,
      );
      expect(contained.field, const Rect.fromLTWH(8, 28, 396, 56));
    });

    test('predictive back shrinks the view to 90 %, off the swiped edge', () {
      const screen = Size(412, 915);
      const bar = Rect.fromLTWH(26, 4, 360, 56);
      final back = expressiveSearchViewGeometry(
        screen: screen,
        collapsed: bar,
        progress: 1,
        backProgress: 1,
      );
      expect(back.surface.width, closeTo(412 * 0.9, 0.01));
      expect(back.surface.height, closeTo(915 * 0.9, 0.01));
      // Swiped from the left: towards the right, clamped to the bar's
      // left edge (Compose's coerceAtMost(collapsedBounds.left)).
      expect(back.surface.left, 26);
      expect(back.corner, 28);
    });
  });

  group('ExpressiveSearchField (Cody: search field)', () {
    testWidgets('search clear and cancel notify and release focus', (
      tester,
    ) async {
      var query = '';
      var cancels = 0;
      final controller = TextEditingController();
      final focus = FocusNode();
      await tester.pumpWidget(
        _app(
          ExpressiveSearchField(
            controller: controller,
            focusNode: focus,
            onChanged: (v) => query = v,
            onCancel: () => cancels++,
          ),
        ),
      );
      await tester.tap(find.byType(EditableText));
      await tester.enterText(find.byType(EditableText), 'weekend');
      await tester.pumpAndSettle();
      expect(query, 'weekend');
      await tester.tap(find.bySemanticsLabel('Clear'));
      await tester.pumpAndSettle();
      expect(query, '');
      expect(focus.hasFocus, true);
      await tester.enterText(find.byType(EditableText), 'work');
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Cancel search'));
      await tester.pumpAndSettle();
      expect(query, '');
      expect(cancels, 1);
      expect(focus.hasFocus, false);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      focus.dispose();
    });

    testWidgets('toolbar search cancellation clears and releases focus', (
      tester,
    ) async {
      var query = '';
      var cancelled = false;
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) => cancelled
                ? const SizedBox()
                : ExpressiveSearchField(
                    onChanged: (v) => query = v,
                    onCancel: () => setState(() => cancelled = true),
                  ),
          ),
        ),
      );
      await tester.enterText(find.byType(EditableText), 'Weekend');
      await tester.pumpAndSettle();
      expect(query, 'Weekend');
      await tester.tap(find.bySemanticsLabel('Cancel search'));
      await tester.pumpAndSettle();
      expect(query, '');
      expect(cancelled, isTrue);
      expect(find.bySemanticsLabel('Cancel search'), findsNothing);
    });

    testWidgets('submits on the keyboard\'s search action', (tester) async {
      String? submitted;
      await tester.pumpWidget(
        _app(ExpressiveSearchField(onSubmitted: (v) => submitted = v)),
      );
      await tester.enterText(find.byType(EditableText), 'figs');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      expect(submitted, 'figs');
    });

    testWidgets('a tap on the pill off its words, the search glyph too, '
        'focuses it, as a tap on Compose\'s decorated field does', (
      tester,
    ) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(_app(ExpressiveSearchField(focusNode: focus)));
      final pill = tester.getRect(find.byType(ExpressiveSearchField));
      final line = tester.getRect(find.byType(EditableText));
      // The leading glyph's 48dp slot, and the pill's air under the words.
      for (final point in [
        pill.centerLeft + const Offset(28, 0),
        Offset(line.center.dx, line.bottom + 6),
      ]) {
        expect(line.contains(point), isFalse);
        expect(pill.contains(point), isTrue);
        focus.unfocus();
        await tester.pump();
        await tester.tapAt(point);
        await tester.pump();
        expect(focus.hasFocus, isTrue, reason: '$point');
      }
    });
  });
}
