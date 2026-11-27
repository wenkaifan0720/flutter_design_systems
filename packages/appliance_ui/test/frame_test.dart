// The app frame (frame.dart), on what it draws: a place's page
// framed by its places and the app's act, each keyed on its hit target, at
// a phone's, a tablet's and a desk's width; a pushed page's bar finds its
// way back, a sheet's its close key, a place's nothing; the router's pages
// raise and close; a phone's key strip yields to a pushed page; the states
// a page shows while its data comes and when it cannot; the preset by name.
import 'package:appliance_ui/appliance_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

const _exit = ValueKey('exit');

const _tabs = [
  ApplianceTab(LucideIcons.house, 'Home', key: ValueKey('open-home')),
  ApplianceTab(LucideIcons.store, 'Shop', key: ValueKey('open-shop')),
];

Widget _page(String title) => Builder(
  builder: (context) => ApplianceScreen(
    topBar: ApplianceAppBar(
      title: title,
      leading: ApplianceAppBar.autoLeading(context, key: _exit),
    ),
    body: Text('$title body'),
  ),
);

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void _size(WidgetTester tester, double width) {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  for (final width in [390.0, 800.0, 1280.0]) {
    testWidgets('a place at $width: its places and the act, keyed', (
      tester,
    ) async {
      _size(tester, width);
      var acted = 0;
      await tester.pumpWidget(
        AppliancePreview(
          tabs: _tabs,
          action: ApplianceShellAction(
            icon: LucideIcons.plus,
            label: 'New list',
            accent: true,
            onPressed: (_) => acted++,
            key: const ValueKey('act'),
          ),
          child: _page('Home'),
        ),
      );
      await _settle(tester);
      expect(find.text('Home body'), findsOneWidget);
      expect(find.byKey(_exit), findsNothing, reason: 'a place has no exit');
      expect(find.byKey(const ValueKey('open-shop')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('act')));
      await tester.pump();
      expect(acted, 1);
    });
  }

  testWidgets('a pushed page finds its way back; a sheet its close key', (
    tester,
  ) async {
    _size(tester, 390);
    await tester.pumpWidget(
      AppliancePreview(
        presentation: AppliancePresentation.pushed,
        child: _page('Order'),
      ),
    );
    await _settle(tester);
    expect(find.text('Order body'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(_exit),
        matching: find.byIcon(LucideIcons.arrowLeft),
      ),
      findsOneWidget,
    );

    await tester.pumpWidget(
      AppliancePreview(
        presentation: AppliancePresentation.sheet,
        brightness: Brightness.dark,
        child: _page('Filter'),
      ),
    );
    await _settle(tester);
    expect(find.text('Filter body'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(_exit),
        matching: find.byIcon(LucideIcons.x),
      ),
      findsOneWidget,
    );
  });

  testWidgets("the router's pages raise and close by their bar's way out", (
    tester,
  ) async {
    _size(tester, 390);
    final stack = <Page<void>>[
      AppliancePage<void>(key: const ValueKey('home'), child: _page('Home')),
    ];
    late StateSetter update;
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        builder: (context, app) => ApplianceHost(child: app!),
        home: StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return Navigator(
              pages: List.of(stack),
              onDidRemovePage: (page) => setState(() => stack.remove(page)),
            );
          },
        ),
      ),
    );
    await _settle(tester);
    expect(find.byKey(_exit), findsNothing);

    update(
      () => stack.add(
        AppliancePage<void>(
          key: const ValueKey('order'),
          child: _page('Order'),
        ),
      ),
    );
    await _settle(tester);
    expect(find.text('Order body'), findsOneWidget);
    await tester.tap(find.byKey(_exit));
    await _settle(tester);
    expect(find.text('Order body'), findsNothing);
    expect(stack, hasLength(1));

    update(
      () => stack.add(
        ApplianceSheetPage<void>(
          key: const ValueKey('filter'),
          child: _page('Filter'),
        ),
      ),
    );
    await _settle(tester);
    expect(find.text('Filter body'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(_exit),
        matching: find.byIcon(LucideIcons.x),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(_exit));
    await _settle(tester);
    expect(find.text('Filter body'), findsNothing);
    expect(stack, hasLength(1));
  });

  testWidgets("a phone's key strip yields to a pushed page; the rail stays", (
    tester,
  ) async {
    Widget frame() => MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, app) => ApplianceHost(child: app!),
      home: ApplianceScaffold(
        destinations: [for (final tab in _tabs) tab.destination],
        selectedIndex: 0,
        onSelected: (_) {},
        showNavigation: false,
        body: const SizedBox.expand(),
      ),
    );
    _size(tester, 390);
    await tester.pumpWidget(frame());
    await _settle(tester);
    // The strip slides away below the screen: nothing of it takes a tap.
    expect(find.byType(ApplianceNavigationBar).hitTestable(), findsNothing);
    tester.view.physicalSize = const Size(800, 844);
    await tester.pumpWidget(frame());
    await _settle(tester);
    expect(find.byType(ApplianceNavigationRail), findsOneWidget);
  });

  testWidgets('loading and failing: the words, and a key to try again', (
    tester,
  ) async {
    _size(tester, 390);
    var tries = 0;
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        builder: (context, app) => ApplianceHost(child: app!),
        home: ApplianceScreen(
          body: Column(
            children: [
              const ApplianceLoadingState(),
              ApplianceErrorState(
                title: 'Could not load the orders',
                message: 'Check the connection.',
                onRetry: () => tries++,
              ),
              const ApplianceInput(labelText: 'Order number'),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Loading'), findsOneWidget);
    expect(find.text('Could not load the orders'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(tries, 1);
    await tester.enterText(find.byType(ApplianceInput), '204118');
    await tester.pump();
    expect(find.text('204118'), findsOneWidget);
    // The ring turns for as long as it stands; take it down.
    await tester.pumpWidget(const SizedBox());
  });

  test('the preset by name', () {
    expect(
      [for (final p in ApplianceThemeData.palettes) p.id],
      ['warm', 'mint', 'butter', 'powder', 'blush', 'slate'],
    );
    expect(
      ApplianceThemeData.preset('warm', Brightness.dark).colors,
      ApplianceThemeData.dark().colors,
    );
    expect(
      ApplianceThemeData.preset('warm', Brightness.light).colors,
      ApplianceThemeData.light().colors,
    );
  });
}
