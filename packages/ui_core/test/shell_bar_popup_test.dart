// The bar under a popup on a branch: a dialog, a menu, a select's list or a
// sheet over a branch's page is no page pushed, so the bar stays and the
// page's footer stays where it is; only a page route over the root hides
// it ([RawAdaptiveShell.hideBarOnPush]).
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_harness.dart';

const List<RawNavigationDestination> _destinations = [
  RawNavigationDestination(label: 'Books', icon: IconData(0xe318)),
  RawNavigationDestination(label: 'Add', icon: IconData(0xe145)),
];

// A select's list or a menu: a popup route over the page, as a look's
// select or date picker pushes on the nearest navigator.
class _Popup extends PopupRoute<void> {
  @override
  Color? get barrierColor => null;
  @override
  bool get barrierDismissible => true;
  @override
  String? get barrierLabel => 'Dismiss';
  @override
  Duration get transitionDuration => const Duration(milliseconds: 150);
  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> a,
    Animation<double> b,
  ) => const Align(child: Text('Menu'));
}

Route<void> _page(String name, {bool opaque = true}) => PageRouteBuilder<void>(
  opaque: opaque,
  pageBuilder: (context, _, _) => Text('$name page'),
);

void main() {
  late RawNavigationDetails shown;
  late List<GlobalKey<NavigatorState>> keys;

  Future<void> pump(WidgetTester tester, {WidgetBuilder? books}) async {
    tester.view.physicalSize = const Size(390, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    keys = [for (final _ in _destinations) GlobalKey<NavigatorState>()];
    await tester.pumpWidget(
      harness(
        RawAdaptiveShell.branches(
          mode: RawNavigationMode.bar,
          destinations: _destinations,
          selectedIndex: 0,
          onDestinationSelected: (_) {},
          destinationBuilder: (context, d, details) =>
              SizedBox(height: 48, child: Center(child: Text(d.label))),
          navigationBuilder: (context, details) {
            shown = details;
            return SizedBox(
              key: const ValueKey('bar'),
              height: 64,
              child: Row(
                children: [
                  for (final d in details.destinations) Expanded(child: d),
                ],
              ),
            );
          },
          navigatorKeys: keys,
          branches: [
            for (final d in _destinations)
              d == _destinations.first && books != null
                  ? books
                  : (context) => Text('${d.label} root'),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  void expectBar({required bool there, required String reason}) {
    expect(shown.visibility.value, there ? 1 : 0, reason: reason);
    expect(shown.pushed, !there, reason: reason);
  }

  testWidgets('a popup over a branch page leaves the bar where it is', (
    tester,
  ) async {
    await pump(tester);
    expectBar(there: true, reason: 'at the root');
    final books = keys[0].currentState!;
    books.push(_Popup()).ignore();
    await tester.pumpAndSettle();
    expect(find.text('Menu'), findsOneWidget);
    expectBar(there: true, reason: 'a popup is no page');
    books.pop();
    await tester.pumpAndSettle();
    expectBar(there: true, reason: 'the popup closed');
    books
        .push(
          RawBottomSheetRoute<void>(
            builder: (context, details) => const Text('Sheet'),
          ),
        )
        .ignore();
    await tester.pumpAndSettle();
    expect(find.text('Sheet'), findsOneWidget);
    expectBar(there: true, reason: 'a bottom sheet is no page');
    books.pop();
    await tester.pumpAndSettle();
    books.push(_page('See-through', opaque: false)).ignore();
    await tester.pumpAndSettle();
    expectBar(there: true, reason: 'a page that shows the one under it');
    books.pop();
    await tester.pumpAndSettle();
    expectBar(there: true, reason: 'back at the root');
  });

  testWidgets('a page hides it, a popup over that page keeps it hidden, and '
      'Back closes the popup before the page', (tester) async {
    await pump(tester);
    final books = keys[0].currentState!;
    books.push(_page('Detail')).ignore();
    await tester.pumpAndSettle();
    expectBar(there: false, reason: 'a page pushed');
    books.push(_Popup()).ignore();
    await tester.pumpAndSettle();
    expectBar(there: false, reason: 'a popup over the page');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Menu'), findsNothing, reason: 'Back closes the popup');
    expect(find.text('Detail page'), findsOneWidget);
    expectBar(there: false, reason: 'the page is still up');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Books root'), findsOneWidget);
    expectBar(there: true, reason: 'popped to the root');
  });

  testWidgets('Back with a popup over a branch root closes the popup, and the '
      'bar never moves', (tester) async {
    await pump(tester);
    final books = keys[0].currentState!;
    books.push(_Popup()).ignore();
    await tester.pumpAndSettle();
    final at = tester.getTopLeft(find.byKey(const ValueKey('bar')));
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(tester.getTopLeft(find.byKey(const ValueKey('bar'))), at);
    await tester.pumpAndSettle();
    expect(find.text('Menu'), findsNothing);
    expect(find.text('Books root'), findsOneWidget);
    expectBar(there: true, reason: 'the popup closed');
  });

  testWidgets('a page swapped for another over the root, or removed under '
      'one, hides and shows the bar by the pages left', (tester) async {
    await pump(tester);
    final books = keys[0].currentState!;
    books.push(_page('Detail')).ignore();
    await tester.pumpAndSettle();
    books.pushReplacement(_page('Other')).ignore();
    await tester.pumpAndSettle();
    expectBar(there: false, reason: 'a page replaced by a page');
    books.popUntil((route) => route.isFirst);
    await tester.pumpAndSettle();
    expectBar(there: true, reason: 'popped to the root');
    final detail = _page('Detail');
    books.push(detail).ignore();
    books.push(_Popup()).ignore();
    await tester.pumpAndSettle();
    books.removeRoute(detail);
    await tester.pumpAndSettle();
    expectBar(there: true, reason: 'the page removed under the popup');
  });
  testWidgets('a popover open on a branch page (a date field\'s calendar) '
      'holds Back but leaves the bar where it is', (tester) async {
    await pump(
      tester,
      books: (context) => Align(
        child: RawPopover(
          semanticLabel: 'Calendar',
          anchorBuilder: (context, anchor) =>
              GestureDetector(onTap: anchor.toggle, child: const Text('Due')),
          overlayBuilder: (context, info) =>
              const SizedBox(width: 200, height: 160, child: Text('Calendar')),
        ),
      ),
    );
    final at = tester.getRect(find.byKey(const ValueKey('bar')));
    await tester.tap(find.text('Due'));
    await tester.pumpAndSettle();
    expect(find.text('Calendar'), findsOneWidget);
    expectBar(there: true, reason: 'a popover is no page');
    expect(tester.getRect(find.byKey(const ValueKey('bar'))), at);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Calendar'), findsNothing, reason: 'Back closed it');
    expect(find.text('Due'), findsOneWidget, reason: 'the page stays');
    expectBar(there: true, reason: 'the popover closed');
  });
}
