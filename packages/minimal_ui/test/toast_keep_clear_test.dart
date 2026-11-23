import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

Widget _host(Widget child) => MinimalHost(
  light: MinimalThemeData.preset('standard', Brightness.light),
  dark: MinimalThemeData.preset('standard', Brightness.dark),
  brightness: Brightness.light,
  child: child,
);

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

double _toastFoot(WidgetTester tester) =>
    tester.getRect(find.text('Saved')).bottom;

void main() {
  testWidgets('a toast stands above a navigation bar along the foot, and '
      'drops to the foot once the bar has gone', (tester) async {
    _phone(tester);
    final bar = ValueNotifier<bool>(true);
    addTearDown(bar.dispose);
    await tester.pumpWidget(
      MaterialApp(
        builder: (_, child) => _host(child!),
        home: ValueListenableBuilder<bool>(
          valueListenable: bar,
          builder: (context, shown, _) => Column(
            children: [
              const Expanded(child: MinimalScaffold(body: Text('Agenda'))),
              if (shown)
                MinimalNavigationBar(
                  items: const [
                    MinimalNavItem(
                      Icons.today,
                      'Today',
                      ValueKey<String>('today'),
                    ),
                    MinimalNavItem(
                      Icons.settings,
                      'Settings',
                      ValueKey<String>('settings'),
                    ),
                  ],
                  selectedIndex: 0,
                  onDestinationSelected: (_) {},
                ),
            ],
          ),
        ),
      ),
    );
    final barTop = tester.getRect(find.byType(MinimalNavigationBar)).top;
    showMinimalSnackBar(tester.element(find.text('Agenda')), 'Saved');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(_toastFoot(tester), lessThan(barTop));

    bar.value = false;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(_toastFoot(tester), greaterThan(barTop));
    await tester.pump(MinimalChromeMetrics.toast);
    await tester.pumpAndSettle();
  });

  testWidgets('a toast on a page pushed over the navigation bar stands at the '
      'foot, and above the bar again once that page has gone', (tester) async {
    _phone(tester);
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        builder: (_, child) => _host(child!),
        home: Column(
          children: [
            const Expanded(child: MinimalScaffold(body: Text('Agenda'))),
            MinimalNavigationBar(
              items: const [
                MinimalNavItem(Icons.today, 'Today', ValueKey<String>('today')),
                MinimalNavItem(
                  Icons.settings,
                  'Settings',
                  ValueKey<String>('settings'),
                ),
              ],
              selectedIndex: 0,
              onDestinationSelected: (_) {},
            ),
          ],
        ),
      ),
    );
    final barTop = tester.getRect(find.byType(MinimalNavigationBar)).top;
    navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (context) => const MinimalScaffold(body: Text('Detail')),
      ),
    );
    await tester.pumpAndSettle();
    showMinimalSnackBar(tester.element(find.text('Detail')), 'Saved');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(_toastFoot(tester), greaterThan(barTop));

    navigator.currentState!.pop();
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
    showMinimalSnackBar(tester.element(find.text('Agenda')), 'Saved');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(_toastFoot(tester), lessThan(barTop));
    await tester.pump(MinimalChromeMetrics.toast);
    await tester.pumpAndSettle();
  });

  testWidgets("a toast stands above a page's footer, and drops to the foot "
      'once that page has gone', (tester) async {
    _phone(tester);
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        builder: (_, child) => _host(child!),
        home: const MinimalScaffold(body: Text('List')),
      ),
    );
    navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (context) => MinimalScaffold(
          footer: MinimalButton(
            'Save',
            expand: true,
            onPressed: () {
              showMinimalSnackBar(context, 'Saved');
              Navigator.of(context).pop();
            },
          ),
          body: const Text('Form'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final footerTop = tester
        .getRect(
          find.ancestor(
            of: find.text('Save'),
            matching: find.byType(MinimalButton),
          ),
        )
        .top;

    final context = tester.element(find.text('Form'));
    showMinimalSnackBar(context, 'Saved');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(_toastFoot(tester), lessThan(footerTop));

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
    expect(find.text('Form'), findsNothing);
    expect(_toastFoot(tester), greaterThan(footerTop));
    await tester.pump(MinimalChromeMetrics.toast);
    await tester.pumpAndSettle();
  });
}
