// A select in a form's column spans it, as the fields beside it do; alone on
// a wide window it stops at its own widest.
import 'package:appliance_ui/appliance_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

Future<double> _width(WidgetTester tester, {required bool inForm}) async {
  tester.view
    ..physicalSize = const Size(1440, 900)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final select = ApplianceSelect<String>(
    labelText: 'Status',
    value: 'want',
    items: const [
      ApplianceSelectItem(value: 'want', label: 'Want to read'),
      ApplianceSelectItem(value: 'reading', label: 'Reading'),
    ],
    onChanged: (_) {},
  );
  final column = Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      select,
      const ApplianceTextField(labelText: 'Title'),
    ],
  );
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) =>
          ApplianceHost(brightness: Brightness.light, child: app!),
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 800,
          child: inForm ? ApplianceForm(child: column) : column,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  // The key itself, not the slot the select's row holds for it.
  final key = find.descendant(
    of: find.byType(ApplianceSelect<String>),
    matching: find.byWidgetPredicate(
      (w) => '${w.runtimeType}' == 'ApplianceSurface',
    ),
  );
  return tester.getSize(key.first).width;
}

void main() {
  setUpAll(applianceLoadFonts);

  testWidgets("a select in a form spans the form's column", (tester) async {
    expect(await _width(tester, inForm: true), 800);
  });

  testWidgets('a select alone stops at its widest', (tester) async {
    expect(
      await _width(tester, inForm: false),
      lessThanOrEqualTo(ApplianceSelect.maxWideWidth),
    );
  });
}
