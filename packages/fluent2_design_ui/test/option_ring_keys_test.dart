// A combobox's and a tag picker's options wear the keys' ring after a key,
// as a select's options do: a list a press opened marks its chosen option
// alone (pill, check and tint), never with a ring that reads as the keys'
// place on it.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:fluent2_design_ui/src/fluent2_design/components/input/field_core.dart'
    show Fluent2OptionFace;

const _people = [
  Fluent2Option('maya', 'Maya Reed'),
  Fluent2Option('sam', 'Sam Okafor'),
  Fluent2Option('noor', 'Noor Haddad'),
];

Future<void> _pump(WidgetTester t, Widget field) async {
  t.view.devicePixelRatio = 1;
  t.view.physicalSize = const Size(800, 600);
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, route) =>
          Fluent2Theme(data: Fluent2ThemeData.lapis(), child: route!),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: 320, child: field),
          ),
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
}

Iterable<Fluent2OptionFace> get _ringed => find
    .byType(Fluent2OptionFace)
    .evaluate()
    .map((e) => e.widget as Fluent2OptionFace)
    .where((f) => f.highlighted);

void main() {
  testWidgets('a combobox a press opened marks its chosen option without a '
      'ring; a key brings the ring', (t) async {
    await _pump(
      t,
      Fluent2Combobox<String>(
        label: 'Assignee',
        value: 'maya',
        options: _people,
        onChanged: (_) {},
      ),
    );
    await t.tap(find.byType(EditableText));
    await t.pumpAndSettle();
    expect(find.byType(Fluent2OptionFace), findsWidgets);
    final chosen = find
        .byType(Fluent2OptionFace)
        .evaluate()
        .map((e) => e.widget as Fluent2OptionFace)
        .where((f) => f.selected);
    expect(chosen.map((f) => f.label), ['Maya Reed']);
    expect(_ringed, isEmpty);
    await t.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await t.pumpAndSettle();
    expect(_ringed.map((f) => f.label), hasLength(1));
  });

  testWidgets('a tag picker a press opened shows no ring until a key', (
    t,
  ) async {
    await _pump(
      t,
      Fluent2MultiSelect<String>(
        label: 'Reviewers',
        options: _people,
        selected: const [],
        onChanged: (_) {},
      ),
    );
    await t.tap(find.byType(EditableText));
    await t.pumpAndSettle();
    if (find.byType(Fluent2OptionFace).evaluate().isEmpty) {
      // Its list opens as the field is typed in.
      await t.enterText(find.byType(EditableText), 'a');
      await t.pumpAndSettle();
    }
    expect(find.byType(Fluent2OptionFace), findsWidgets);
    expect(_ringed, isEmpty);
    await t.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await t.pumpAndSettle();
    expect(_ringed, hasLength(1));
  });
}
