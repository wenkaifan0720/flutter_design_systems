// A control in FrostedFormField that names itself in the label's words is read once ("Text size", not
// "Text size Text size"), and a slider says its formatter's words for its value.

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';

Future<void> _pump(WidgetTester t, Widget field) async {
  await t.pumpWidget(
    MaterialApp(
      builder: (context, page) => FrostedHost(child: page!),
      home: FrostedScaffold(
        body: Padding(padding: const EdgeInsets.all(16), child: field),
      ),
    ),
  );
  await t.pumpAndSettle();
}

String _all(SemanticsNode n) {
  final words = <String>[];
  void walk(SemanticsNode node) {
    // A node merged into its parent is heard in the parent's words.
    if (node.isMergedIntoParent) return;
    final d = node.getSemanticsData();
    if (d.label.isNotEmpty) words.add(d.label);
    node.visitChildren((c) {
      walk(c);
      return true;
    });
  }

  walk(n);
  return words.join(' | ');
}

void main() {
  testWidgets(
    'a slider under its own label is named once, its value in words',
    (t) async {
      final handle = t.ensureSemantics();
      await _pump(
        t,
        FrostedFormField(
          labelText: 'Text size',
          helperText: 'How large the words stand',
          child: FrostedSlider(
            semanticLabel: 'Text size',
            value: 1.3,
            min: 0.9,
            max: 1.3,
            divisions: 4,
            semanticFormatterCallback: (v) => '${(v * 100).round()}%',
            onChanged: (_) {},
          ),
        ),
      );
      final node = t.getSemantics(find.byType(FrostedSlider));
      final data = node.getSemanticsData();
      expect(data.value, '130%');
      final heard = _all(
        t.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!,
      );
      expect(RegExp('Text size').allMatches(heard).length, 1, reason: heard);
      handle.dispose();
    },
  );

  testWidgets('a switch under its own label is named once', (t) async {
    final handle = t.ensureSemantics();
    await _pump(
      t,
      FrostedFormField(
        labelText: 'Favourite',
        child: FrostedSwitch(
          value: true,
          semanticLabel: 'Favourite',
          onChanged: (_) {},
        ),
      ),
    );
    final heard = _all(
      t.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!,
    );
    expect(RegExp('Favourite').allMatches(heard).length, 1, reason: heard);
    handle.dispose();
  });
}
