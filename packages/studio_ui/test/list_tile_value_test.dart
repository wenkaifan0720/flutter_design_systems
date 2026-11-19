// A list tile's value at the end takes its own width, up to under half the
// row, and the title the rest: a short date beside a title leaves the title
// the row (Stint's Up next wrapped "Proof the studio map" at half the row,
// the date's slot as wide as the title's, in Appliance, whose tile Studio's
// shares), and a long value ends in an ellipsis short of the title.
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';

Future<void> _show(WidgetTester tester, String value) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = const Size(390 * 2, 600 * 2);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) =>
          StudioHost(brightness: Brightness.light, child: app!),
      home: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.all(StudioSpacing.regular),
          child: StudioListGroup(
            header: 'Up next',
            children: [
              StudioListTile(
                title: 'Proof the studio map',
                subtitle: 'Open studio',
                leading: const StudioLamp(on: true),
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
  setUpAll(studioLoadFonts);

  testWidgets('a short value leaves the title the row', (tester) async {
    await _show(tester, 'Nov 20');
    final title = tester.getSize(find.text('Proof the studio map'));
    final value = tester.getSize(find.text('Nov 20'));
    // One line, as the value is.
    expect(title.height, lessThan(value.height * 1.5));
    // The value's own width, not half the row.
    expect(value.width, lessThan(80));
  });

  testWidgets('a long value ends short of half the row', (tester) async {
    const long = 'Due on the morning of Friday, 20 November';
    await _show(tester, long);
    final row = tester.getSize(find.byType(StudioListTile)).width;
    final value = tester.getSize(find.text(long)).width;
    expect(value, lessThanOrEqualTo(row * 0.45));
    // The title keeps the rest, clear of the value.
    expect(
      tester.getTopRight(find.text('Proof the studio map')).dx,
      lessThanOrEqualTo(tester.getTopLeft(find.text(long)).dx),
    );
  });
}
