import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

final _navigator = GlobalKey<NavigatorState>();

Widget _app(Widget home) => WidgetsApp(
  navigatorKey: _navigator,
  color: const Color(0xffeeeeee),
  pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
    settings: settings,
    pageBuilder: (context, _, _) => builder(context),
  ),
  builder: (context, child) =>
      NeumorphicHost(brightness: Brightness.light, child: child!),
  home: home,
);

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

const _bar = NeumorphicNavigationBar(
  items: [
    NeumorphicNavItem(label: 'Today', icon: NeumorphicGlyphs.house),
    NeumorphicNavItem(label: 'Rooms', icon: NeumorphicGlyphs.house),
  ],
);

Future<void> _toast(WidgetTester tester, String on) async {
  showNeumorphicToast(tester.element(find.text(on)), message: 'Saved');
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

double _toastFoot(WidgetTester tester) =>
    tester.getRect(find.text('Saved').last).bottom;

Future<void> _settle(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 8));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadNeumorphicFonts);

  testWidgets('a toast stands above the navigation bar, and drops to the foot '
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
              const Expanded(child: NeumorphicScaffold(body: Text('Agenda'))),
              if (bar) _bar,
            ],
          ),
        ),
      ),
    );
    final barTop = tester.getRect(find.byType(NeumorphicNavigationBar)).top;
    await _toast(tester, 'Agenda');
    expect(_toastFoot(tester), lessThan(barTop));

    shown.value = false;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(_toastFoot(tester), greaterThan(barTop));
    await _settle(tester);
  });

  testWidgets("a toast stands above a page's footer", (tester) async {
    _phone(tester);
    await tester.pumpWidget(
      _app(
        NeumorphicScaffold(
          footer: NeumorphicButton('Save', onPressed: () {}),
          body: const Text('Form'),
        ),
      ),
    );
    final footerTop = tester
        .getRect(
          find.ancestor(
            of: find.text('Save'),
            matching: find.byType(NeumorphicButton),
          ),
        )
        .top;
    await _toast(tester, 'Form');
    expect(_toastFoot(tester), lessThan(footerTop));
    await _settle(tester);
  });

  testWidgets('a toast on a page pushed over the navigation bar stands at the '
      'foot, and above the bar again once that page has gone', (tester) async {
    _phone(tester);
    await tester.pumpWidget(
      _app(
        const Column(
          children: [
            Expanded(child: NeumorphicScaffold(body: Text('Agenda'))),
            _bar,
          ],
        ),
      ),
    );
    final barTop = tester.getRect(find.byType(NeumorphicNavigationBar)).top;
    _navigator.currentState!.push(
      PageRouteBuilder<void>(
        pageBuilder: (context, _, _) =>
            const NeumorphicScaffold(body: Text('Detail')),
      ),
    );
    await tester.pumpAndSettle();
    await _toast(tester, 'Detail');
    expect(_toastFoot(tester), greaterThan(barTop));
    await _settle(tester);

    _navigator.currentState!.pop();
    await tester.pumpAndSettle();
    await _toast(tester, 'Agenda');
    expect(_toastFoot(tester), lessThan(barTop));
    await _settle(tester);
  });
}
