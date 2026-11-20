// A trailing value uses its measured width and leaves the rest of the row for the title.
import 'package:appliance_ui/appliance_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _show(WidgetTester tester, String value) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = const Size(390 * 2, 600 * 2);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) =>
          ApplianceHost(brightness: Brightness.light, child: app!),
      home: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.all(ApplianceSpacing.regular),
          child: ApplianceListGroup(
            header: 'Up next',
            children: [
              ApplianceListTile(
                title: 'Proof the studio map',
                subtitle: 'Open studio',
                leading: const ApplianceLamp(lit: true),
                trailingText: value,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(applianceLoadFonts);

  testWidgets('a short value leaves the title the row', (tester) async {
    await _show(tester, 'Nov 20');
    final title = tester.getSize(find.text('Proof the studio map'));
    final value = tester.getSize(find.text('Nov 20'));
    // One line each, in the same type size.
    expect(title.height, value.height);
    // The value's own width, not half the row.
    expect(value.width, lessThan(80));
  });

  testWidgets('a long value ends short of half the row', (tester) async {
    const long = 'Due on the morning of Friday, 20 November';
    await _show(tester, long);
    final row = tester.getSize(find.byType(ApplianceListTile)).width;
    final value = tester.getSize(find.text(long)).width;
    expect(value, lessThanOrEqualTo(row * 0.45));
    // The title keeps the rest, clear of the value.
    expect(
      tester.getTopRight(find.text('Proof the studio map')).dx,
      lessThanOrEqualTo(tester.getTopLeft(find.text(long)).dx),
    );
  });
}
