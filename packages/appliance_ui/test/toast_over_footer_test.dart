// A toast stands above an ApplianceScreen's footer, so its keys stay in
// reach: on a pushed page whose footer is the screen's foot, and on a
// place's first page, where the footer stands on a phone's key strip.
import 'package:appliance_ui/appliance_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

const _places = [
  ApplianceDestination(icon: Icons.home_outlined, label: 'Home'),
  ApplianceDestination(icon: Icons.storefront_outlined, label: 'Shop'),
];

Widget _page(String title) => ApplianceScreen(
  topBar: ApplianceAppBar(title: title),
  body: const Text('A kettle'),
  footer: ApplianceButton.filled(
    'Delete',
    isDestructiveAction: true,
    onPressed: () {},
  ),
);

Future<void> _phone(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) =>
          ApplianceHost(brightness: Brightness.light, child: app!),
      home: home,
    ),
  );
  await tester.pumpAndSettle();
}

Future<Rect> _toast(WidgetTester tester) async {
  showApplianceToast(tester.element(find.text('A kettle')), 'Saved');
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
  return tester.getRect(find.text('Saved'));
}

void main() {
  setUpAll(applianceLoadFonts);

  testWidgets("a toast stands above a page's footer", (tester) async {
    await _phone(tester, _page('Kettle'));
    final key = tester.getRect(find.byType(ApplianceButton));
    expect((await _toast(tester)).bottom, lessThanOrEqualTo(key.top));
  });

  testWidgets("a toast stands above a footer on a phone's key strip", (
    tester,
  ) async {
    await _phone(
      tester,
      ApplianceScaffold.branches(
        destinations: _places,
        onSelected: (_) {},
        branches: [(context) => _page('Home'), (context) => _page('Shop')],
      ),
    );
    final key = tester.getRect(find.byType(ApplianceButton));
    final strip = tester.getRect(find.byType(ApplianceNavigationBar)).top;
    expect(key.bottom, lessThanOrEqualTo(strip));
    expect((await _toast(tester)).bottom, lessThanOrEqualTo(key.top));
  });
}
