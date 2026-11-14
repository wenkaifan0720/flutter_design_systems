import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

const List<MinimalNavItem> _tabs = [
  MinimalNavItem(Icons.today, 'Today'),
  MinimalNavItem(Icons.list, 'Habits'),
];

Widget _preview(MinimalPresentation presentation) => MinimalPreview(
  light: MinimalThemeData.preset('standard', Brightness.light),
  dark: MinimalThemeData.preset('standard', Brightness.dark),
  brightness: Brightness.light,
  presentation: presentation,
  tabs: _tabs,
  child: const MinimalScaffold(
    topBar: MinimalAppBar(title: 'Habits', subtitle: 'HAB-4'),
    body: Text('Detail body'),
  ),
);

MinimalRouteChrome _register(WidgetTester tester) =>
    MinimalRouteChrome.of(tester.element(find.text('Detail body')));

void main() {
  testWidgets('a root leads with its title and stands over the tab bar', (
    tester,
  ) async {
    // A phone: from MinimalShell.railFrom the tabs stand in a rail instead.
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_preview(MinimalPresentation.root));
    await tester.pumpAndSettle();
    expect(_register(tester), MinimalRouteChrome.root);
    final title = tester.widget<Text>(find.text('Habits').first);
    expect(title.style?.fontSize, MinimalChromeMetrics.barTitle);
    expect(find.byType(MinimalNavigationBar), findsOneWidget);
    expect(find.byWidgetPredicate(_labelled('Back')), findsNothing);
    expect(
      MinimalShellInsets.of(tester.element(find.text('Detail body'))),
      greaterThan(0),
    );
  });

  testWidgets('a pushed page gets the back button, and never pops onto the '
      'blank stage', (tester) async {
    await tester.pumpWidget(_preview(MinimalPresentation.pushed));
    await tester.pumpAndSettle();
    final page = find.text('Detail body');
    expect(page, findsOneWidget);
    expect(_register(tester), MinimalRouteChrome.pushed);
    expect(find.byType(MinimalNavigationBar), findsNothing);

    await tester.tap(find.byWidgetPredicate(_labelled('Back')));
    await tester.pumpAndSettle();
    expect(page, findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(page, findsOneWidget);

    // A pop that takes the page anyway raises it again.
    Navigator.of(tester.element(page)).pop();
    await tester.pumpAndSettle();
    expect(page, findsOneWidget);
  });

  testWidgets('a sheet page stands in the card with its close', (tester) async {
    await tester.pumpWidget(_preview(MinimalPresentation.sheet));
    await tester.pumpAndSettle();
    expect(find.text('Detail body'), findsOneWidget);
    expect(_register(tester), MinimalRouteChrome.sheet);
    expect(find.byWidgetPredicate(_labelled('Back')), findsNothing);

    await tester.tap(find.byWidgetPredicate(_labelled('Close')));
    await tester.pumpAndSettle();
    expect(find.text('Detail body'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Detail body'), findsOneWidget);
  });

  testWidgets('a root keeps its register under a raised sheet', (tester) async {
    await tester.pumpWidget(_preview(MinimalPresentation.root));
    await tester.pumpAndSettle();
    showMinimalBottomSheet<void>(
      tester.element(find.text('Detail body')),
      title: 'New habit',
      builder: (_) => const Text('Sheet body'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sheet body'), findsOneWidget);
    expect(_register(tester), MinimalRouteChrome.root);
    expect(
      MinimalRouteChrome.of(tester.element(find.text('Sheet body'))),
      MinimalRouteChrome.sheet,
    );

    await tester.tap(find.byWidgetPredicate(_labelled('Close')));
    await tester.pumpAndSettle();
    expect(find.text('Sheet body'), findsNothing);
  });

  testWidgets('a pushed page that authors no bar still gets the way out', (
    tester,
  ) async {
    await tester.pumpWidget(
      MinimalPreview(
        light: MinimalThemeData.preset('standard', Brightness.light),
        dark: MinimalThemeData.preset('standard', Brightness.dark),
        presentation: MinimalPresentation.pushed,
        child: const MinimalScaffold(body: Text('Bare')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byWidgetPredicate(_labelled('Back')), findsOneWidget);
  });

  group('from MinimalShell.railFrom of its own box', () {
    void wide(WidgetTester tester) {
      tester.view
        ..physicalSize = const Size(1440, 900)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }

    testWidgets('a root stands its tabs in a rail, the page beside it', (
      tester,
    ) async {
      wide(tester);
      await tester.pumpWidget(_preview(MinimalPresentation.root));
      await tester.pumpAndSettle();
      expect(find.byType(MinimalNavigationBar), findsNothing);
      expect(find.byType(MinimalNavigationRail), findsOneWidget);
      expect(
        tester.getTopLeft(find.byType(MinimalScaffold)).dx,
        MinimalNavigationRail.width,
      );
      expect(
        MinimalShellInsets.of(tester.element(find.text('Detail body'))),
        0,
      );
    });

    testWidgets('a phone-wide box in a wide window keeps the bar', (
      tester,
    ) async {
      wide(tester);
      await tester.pumpWidget(
        Center(
          child: SizedBox(
            width: 430,
            height: 800,
            child: _preview(MinimalPresentation.root),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(MinimalNavigationBar), findsOneWidget);
      expect(find.byType(MinimalNavigationRail), findsNothing);
    });

    testWidgets('a sheet page stands as a centred card', (tester) async {
      wide(tester);
      await tester.pumpWidget(_preview(MinimalPresentation.sheet));
      await tester.pumpAndSettle();
      expect(_register(tester), MinimalRouteChrome.sheet);
      final page = tester.getRect(find.byType(MinimalScaffold));
      expect(page.width, lessThanOrEqualTo(MinimalBottomSheet.centredWidth));
      expect(page.center.dx, closeTo(720, 1));
      // Clear of the bottom edge a phone's sheet rises from.
      expect(page.bottom, lessThan(900 - MinimalSpacing.s24));
      expect(find.byWidgetPredicate(_labelled('Close')), findsOneWidget);
    });
  });
}

bool Function(Widget) _labelled(String label) =>
    (widget) => widget is MinimalIconButton && widget.label == label;
