// An ApplianceScreen holds its bar and its footer to the body's measure: on
// a wide window the title starts where the body starts, the bar's actions
// and the footer end where it ends; full bleed, the bar spans the page.
import 'package:appliance_ui/appliance_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

Future<void> _show(WidgetTester tester, {bool fullBleed = false}) async {
  tester.view
    ..physicalSize = const Size(1440, 900)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) =>
          ApplianceHost(brightness: Brightness.light, child: app!),
      home: ApplianceScreen(
        maxWidth: 640,
        fullBleed: fullBleed,
        topBar: ApplianceAppBar(
          title: 'Orders',
          actions: [
            ApplianceIconButton(
              icon: const Icon(LucideIcons.search),
              semanticLabel: 'Search',
              onPressed: () {},
            ),
          ],
        ),
        body: const SizedBox(height: 200, child: Placeholder()),
        footer: ApplianceButton('Check out', onPressed: () {}),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the bar and the footer stand on the body\'s measure', (
    tester,
  ) async {
    await _show(tester);
    final body = tester.getRect(find.byType(Placeholder));
    expect(body.width, 640);
    final title = tester.getRect(find.text('Orders'));
    final search = tester.getRect(find.byType(ApplianceIconButton));
    final pay = tester.getRect(find.byType(ApplianceButton));
    expect(title.left, closeTo(body.left, 1));
    expect(search.right, closeTo(body.right, 1));
    expect(pay.right, closeTo(body.right, 1));
  });

  testWidgets('full bleed, the bar spans the page', (tester) async {
    await _show(tester, fullBleed: true);
    final title = tester.getRect(find.text('Orders'));
    expect(title.left, lessThan(100));
  });
}
