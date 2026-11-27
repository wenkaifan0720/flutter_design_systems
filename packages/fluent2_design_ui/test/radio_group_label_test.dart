// A radio group's label is drawn over it, as its doc says, and said once,
// as the group's name; under a form field the field draws it instead.
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

Future<void> _show(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) =>
          Fluent2Host(brightness: Brightness.light, child: app!),
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: 400, child: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Fluent2RadioGroup<String> _group({String? label}) => Fluent2RadioGroup<String>(
  label: label,
  value: 'daily',
  onChanged: (_) {},
  options: const [
    Fluent2Radio('daily', 'Daily'),
    Fluent2Radio('weekly', 'Weekly'),
  ],
);

void main() {
  testWidgets("a group's label shows over its radios", (tester) async {
    final semantics = tester.ensureSemantics();
    await _show(tester, _group(label: 'Digest'));
    expect(find.text('Digest'), findsOneWidget);
    final label = tester.getRect(find.text('Digest'));
    final first = tester.getRect(find.text('Daily'));
    expect(label.bottom, lessThanOrEqualTo(first.top));
    expect(
      tester.getSemantics(find.text('Daily')),
      isNot(matchesSemantics(label: 'Digest')),
    );
    expect(find.bySemanticsLabel('Digest'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('a group without a label draws none', (tester) async {
    await _show(tester, _group());
    expect(find.byType(Fluent2Label), findsNothing);
  });

  testWidgets('in a form field, the field draws the label once', (
    tester,
  ) async {
    await _show(tester, Fluent2FormField(labelText: 'Digest', child: _group()));
    expect(find.text('Digest'), findsOneWidget);
  });
}
