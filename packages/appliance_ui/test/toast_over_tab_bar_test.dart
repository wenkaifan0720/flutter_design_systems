// On a phone a toast stands above Appliance's key strip, and drops to the
// screen's foot under a page that covers the frame.
import 'package:appliance_ui/appliance_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

const _places = [
  ApplianceDestination(icon: Icons.home_outlined, label: 'Home'),
  ApplianceDestination(icon: Icons.storefront_outlined, label: 'Shop'),
];

Future<BuildContext> _frame(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) =>
          ApplianceHost(brightness: Brightness.light, child: app!),
      home: ApplianceScaffold(
        destinations: _places,
        selectedIndex: 0,
        onSelected: (_) {},
        body: const Center(child: Text('Today')),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return tester.element(find.text('Today'));
}

double _toastFoot(WidgetTester tester) =>
    tester.getRect(find.text('Added to basket')).bottom;

void main() {
  setUpAll(applianceLoadFonts);

  testWidgets("a toast stands above a phone's key strip", (tester) async {
    final context = await _frame(tester);
    final strip = tester.getRect(find.byType(ApplianceNavigationBar)).top;
    showApplianceToast(context, 'Added to basket');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(_toastFoot(tester), lessThanOrEqualTo(strip));
  });

  testWidgets('a toast under a page that covers the frame keeps to the '
      "screen's foot", (tester) async {
    final context = await _frame(tester);
    final strip = tester.getRect(find.byType(ApplianceNavigationBar)).top;
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => const ColoredBox(
          color: Color(0xFFFFFFFF),
          child: Center(child: Text('Checkout')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    showApplianceToast(
      tester.element(find.text('Checkout')),
      'Added to basket',
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(_toastFoot(tester), greaterThan(strip));
  });
}
