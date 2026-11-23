import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';
import 'package:retro_desktop_ui/retro_desktop_host.dart';

import 'support.dart';

final _navigator = GlobalKey<NavigatorState>();

Widget _app(Widget home) => MaterialApp(
  navigatorKey: _navigator,
  debugShowCheckedModeBanner: false,
  builder: (context, child) =>
      RetroDesktopHost(brightness: Brightness.light, child: child!),
  home: home,
);

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

final _bar = RetroDesktopNavigationBar(
  items: [
    RetroDesktopNavItem(
      label: 'Files',
      short: 'Files',
      icon: RetroDesktopGlyphs.folder,
      onPressed: () {},
    ),
    RetroDesktopNavItem(
      label: 'Inbox',
      short: 'Inbox',
      icon: RetroDesktopGlyphs.inbox,
      onPressed: () {},
    ),
  ],
);

Future<void> _notice(WidgetTester tester, String on) async {
  showRetroDesktopSnackBar(tester.element(find.text(on)), 'Saved');
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

double _noticeFoot(WidgetTester tester) =>
    tester.getRect(find.byType(RetroDesktopSnackBar)).bottom;

Future<void> _settle(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 8));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadRetroDesktopFonts);

  testWidgets('a notice stands above the navigation bar, and drops to the foot '
      'once the bar has gone', (tester) async {
    _phone(tester);
    final shown = ValueNotifier<bool>(true);
    addTearDown(shown.dispose);
    await tester.pumpWidget(
      _app(
        ValueListenableBuilder<bool>(
          valueListenable: shown,
          builder: (context, bar, _) => Column(
            children: [
              const Expanded(
                child: RetroDesktopScaffold(body: Text('Documents')),
              ),
              if (bar) _bar,
            ],
          ),
        ),
      ),
    );
    final barTop = tester.getRect(find.byType(RetroDesktopNavigationBar)).top;
    await _notice(tester, 'Documents');
    expect(_noticeFoot(tester), lessThanOrEqualTo(barTop));

    shown.value = false;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(_noticeFoot(tester), greaterThan(barTop));
    await _settle(tester);
  });

  testWidgets("a notice stands above a page's footer", (tester) async {
    _phone(tester);
    await tester.pumpWidget(
      _app(
        RetroDesktopScaffold(
          footer: RetroDesktopButton('Save', onPressed: () {}),
          body: const Text('Form'),
        ),
      ),
    );
    final footerTop = tester
        .getRect(
          find.ancestor(
            of: find.text('Save'),
            matching: find.byType(RetroDesktopButton),
          ),
        )
        .top;
    await _notice(tester, 'Form');
    expect(_noticeFoot(tester), lessThanOrEqualTo(footerTop));
    await _settle(tester);
  });

  testWidgets('a notice on a page pushed over the navigation bar stands at the '
      'foot, and above the bar again once that page has gone', (tester) async {
    _phone(tester);
    await tester.pumpWidget(
      _app(
        Column(
          children: [
            const Expanded(
              child: RetroDesktopScaffold(body: Text('Documents')),
            ),
            _bar,
          ],
        ),
      ),
    );
    final barTop = tester.getRect(find.byType(RetroDesktopNavigationBar)).top;
    _navigator.currentState!.push(
      const RetroDesktopPage<void>(
        child: RetroDesktopScaffold(body: Text('Detail')),
      ).createRoute(_navigator.currentContext!),
    );
    await tester.pumpAndSettle();
    await _notice(tester, 'Detail');
    expect(_noticeFoot(tester), greaterThan(barTop));
    await _settle(tester);

    _navigator.currentState!.pop();
    await tester.pumpAndSettle();
    await _notice(tester, 'Documents');
    expect(_noticeFoot(tester), lessThanOrEqualTo(barTop));
    await _settle(tester);
  });
}
