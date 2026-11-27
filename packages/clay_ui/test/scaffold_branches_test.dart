// ClayScaffold draws its places through ui_core's adaptive shell at every
// width: a phone's dock is a tab bar, each place heard with its place in it.
// ClayScaffold.branches keeps a stack of pages per place: a page pushed on a
// place stays there while another place is shown, choosing the place again
// goes back to its first page, back pops it, and a phone's dock steps away
// while it stands (a rail stays beside it).
import 'package:clay_ui/clay_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart'
    show MaterialApp, MaterialPageRoute;

const _places = [
  ClayDestination(icon: LucideIcons.sun, label: 'Today'),
  ClayDestination(icon: LucideIcons.listChecks, label: 'Habits'),
];

class _Root extends StatelessWidget {
  const _Root(this.name);

  final String name;

  @override
  Widget build(BuildContext context) => ClayScreen(
    topBar: ClayTopBar(title: name),
    body: ClayButton(
      'Open $name',
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => ClayScreen(
            topBar: ClayTopBar(
              title: '$name detail',
              leading: ClayTopBar.autoLeading(context),
            ),
            body: const SizedBox(height: 40),
          ),
        ),
      ),
    ),
  );
}

class _App extends StatefulWidget {
  const _App();

  @override
  State<_App> createState() => _AppState();
}

class _AppState extends State<_App> {
  int index = 0;

  void show(int place) => setState(() => index = place);

  @override
  Widget build(BuildContext context) => ClayScaffold.branches(
    destinations: _places,
    selectedIndex: index,
    onDestinationSelected: (i) => setState(() => index = i),
    branches: [
      (context) => const _Root('Today'),
      (context) => const _Root('Habits'),
    ],
  );
}

Future<void> _pump(WidgetTester tester, double width, Widget home) async {
  tester.view
    ..physicalSize = Size(width, 800)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => ClayHost(child: child!),
      home: home,
    ),
  );
  await tester.pumpAndSettle();
}

Finder _place(String label, int n) =>
    find.bySemanticsLabel('$label\nTab $n of 2');

void main() {
  testWidgets("a phone's dock is a tab bar, each place a tab in it", (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(
      tester,
      390,
      ClayScaffold(
        destinations: _places,
        onDestinationSelected: (_) {},
        body: const SizedBox.expand(),
      ),
    );
    expect(_place('Today', 1), findsOneWidget);
    expect(_place('Habits', 2), findsOneWidget);
    expect(
      tester.getSemantics(_place('Today', 1)),
      isSemantics(isSelected: true),
    );
    handle.dispose();
  });

  for (final width in [768.0, 1440.0]) {
    testWidgets('at ${width.toInt()} each place is a tab too', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        width,
        ClayScaffold(
          destinations: _places,
          selectedIndex: 1,
          onDestinationSelected: (_) {},
          body: const SizedBox.expand(),
        ),
      );
      expect(_place('Today', 1), findsOneWidget);
      expect(
        tester.getSemantics(_place('Habits', 2)),
        isSemantics(isSelected: true),
      );
      handle.dispose();
    });
  }

  testWidgets('the arrows move along the dock, Enter chooses', (tester) async {
    var chosen = -1;
    await _pump(
      tester,
      390,
      ClayScaffold(
        destinations: _places,
        onDestinationSelected: (i) => chosen = i,
        body: const SizedBox.expand(),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(chosen, 1);
  });

  testWidgets('each place keeps its own pages on a phone', (tester) async {
    await _pump(tester, 390, const _App());
    final dockTop = tester.getTopLeft(find.byType(ClayNavigationBar)).dy;
    await tester.tap(find.text('Open Today'));
    await tester.pumpAndSettle();
    expect(find.text('Today detail'), findsOneWidget);
    // The dock has stepped away, and the page has its room.
    expect(
      tester.getTopLeft(find.byType(ClayNavigationBar)).dy,
      greaterThanOrEqualTo(800),
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Today detail'), findsNothing);
    expect(tester.getTopLeft(find.byType(ClayNavigationBar)).dy, dockTop);

    await tester.tap(find.text('Open Today'));
    await tester.pumpAndSettle();
    final state = tester.state<_AppState>(find.byType(_App));
    state.show(1);
    await tester.pumpAndSettle();
    expect(find.text('Habits'), findsWidgets);
    expect(find.text('Today detail'), findsNothing);
    state.show(0);
    await tester.pumpAndSettle();
    expect(find.text('Today detail'), findsOneWidget);
  });

  testWidgets('choosing the place again goes back to its first page', (
    tester,
  ) async {
    await _pump(tester, 768, const _App());
    await tester.tap(find.text('Open Today'));
    await tester.pumpAndSettle();
    expect(find.text('Today detail'), findsOneWidget);
    // The rail stays beside the pushed page.
    expect(find.byType(ClayNavigationRail), findsOneWidget);
    await tester.tap(_place('Today', 1));
    await tester.pumpAndSettle();
    expect(find.text('Today detail'), findsNothing);
    expect(find.text('Open Today'), findsOneWidget);
  });

  testWidgets("the page's fade above the dock goes with it", (tester) async {
    await _pump(tester, 390, const _App());
    double fade() => tester
        .widget<Opacity>(
          find
              .descendant(
                of: find.byType(ClayScaffold),
                matching: find.byType(Opacity),
              )
              .last,
        )
        .opacity;
    expect(fade(), 1);
    await tester.tap(find.text('Open Today'));
    await tester.pumpAndSettle();
    expect(fade(), 0);
  });

  for (final width in [1024.0, 1440.0]) {
    testWidgets(
      "at ${width.round()} the sidebar's first place stands on the top bar's line",
      (tester) async {
        await _pump(tester, width, const _App());
        final bar = tester.getRect(find.byType(ClayTopBar));
        final place = tester.getRect(_place('Today', 1).first);
        expect(place.center.dy, moreOrLessEquals(bar.center.dy));
      },
    );
  }
}
