// A slider's spoken value: a whole percentage of the range by default, as
// Material's Slider says it, or the app's words through
// semanticFormatterCallback, for the value and the values a screen reader's
// increase and decrease would give.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_harness.dart';

Widget _handle({String Function(double value)? say}) => harness(
  Center(
    child: RawValueHandle(
      value: 12,
      max: 52,
      step: 1,
      onChanged: (_) {},
      semanticLabel: 'Goal',
      semanticFormatterCallback: say,
      builder: (context, states) => const SizedBox(width: 24, height: 24),
    ),
  ),
);

void main() {
  testWidgets('a percentage of the range by default, as Material says it', (
    tester,
  ) async {
    await tester.pumpWidget(_handle());
    final node = tester.getSemantics(find.bySemanticsLabel('Goal'));
    expect(node.value, '23%');
    expect(node.increasedValue, '25%');
    expect(node.decreasedValue, '21%');
  });

  testWidgets('the app\'s words through semanticFormatterCallback', (
    tester,
  ) async {
    await tester.pumpWidget(_handle(say: (v) => '${v.round()} books'));
    final node = tester.getSemantics(find.bySemanticsLabel('Goal'));
    expect(node.value, '12 books');
    expect(node.increasedValue, '13 books');
    expect(node.decreasedValue, '11 books');
  });
}
