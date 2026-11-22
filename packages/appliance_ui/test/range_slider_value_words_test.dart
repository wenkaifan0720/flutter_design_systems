// A range slider says its values as the app formats them: a price's caps
// read in the chosen currency, to the slider and to a screen reader.
import 'package:appliance_ui/appliance_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _show(
  WidgetTester tester,
  Widget child, {
  double scale = 2,
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 620);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, navigator) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: Directionality(
          textDirection: direction,
          child: ApplianceTheme(
            data: ApplianceThemeData.light(),
            child: navigator!,
          ),
        ),
      ),
      home: Center(child: child),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(applianceLoadFonts);
  testWidgets('price thumbs format their values in the selected currency', (
    tester,
  ) async {
    await _show(
      tester,
      ApplianceRangeSlider(
        values: const RawRangeValues(25, 60),
        max: 100,
        startLabel: 'Minimum price',
        onChanged: (_) {},
        semanticFormatterCallback: (v) => '\$${v.round()}',
      ),
    );
    final slider = tester.widget<RawRangeSlider>(find.byType(RawRangeSlider));
    expect(slider.semanticFormatterCallback!(25), r'$25');
    expect(
      tester.getSemantics(find.bySemanticsLabel('Minimum price')).value,
      r'$25',
    );
  });
}
