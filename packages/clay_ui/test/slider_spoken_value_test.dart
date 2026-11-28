// What a screen reader hears of a slider: a whole percentage of its range by
// default, as Material's Slider says it, or the app's own words for the value
// (and for the values a step up and down reach) from semanticFormatterCallback.
import 'package:clay_ui/clay_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

Future<void> _pump(WidgetTester tester, Widget slider) => tester.pumpWidget(
  MaterialApp(
    builder: (context, child) => ClayHost(child: child!),
    home: Center(child: SizedBox(width: 300, child: slider)),
  ),
);

void main() {
  setUpAll(clayLoadFonts);

  testWidgets('a slider says a percentage of its range by default', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(
      tester,
      ClaySlider(
        value: 12,
        min: 1,
        max: 52,
        divisions: 51,
        semanticLabel: 'Goal',
        onChanged: (_) {},
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Goal')),
      isSemantics(isSlider: true, value: '22%'),
    );
    handle.dispose();
  });

  testWidgets("a slider says its value in the app's words", (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(
      tester,
      ClaySlider(
        value: 12,
        min: 1,
        max: 52,
        divisions: 51,
        semanticLabel: 'Goal',
        semanticFormatterCallback: (goal) => '${goal.round()} books',
        onChanged: (_) {},
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Goal')),
      isSemantics(
        isSlider: true,
        value: '12 books',
        increasedValue: '13 books',
        decreasedValue: '11 books',
      ),
    );
    handle.dispose();
  });
}
